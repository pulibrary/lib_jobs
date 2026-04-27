# frozen_string_literal: true
module TMASGateCounts
  class Job < LibJob
    def initialize(
      airtable_client_class: AirtableClient,
      fetch_tmas_counts_class: FetchTMASCounts,
      next_date_class: NextDateToProcess
    )
      @airtable_client_class = airtable_client_class
      @fetch_tmas_counts_class = fetch_tmas_counts_class
      @next_date_class = next_date_class
      super(category: 'TMASGateCounts')
    end

    private

    def handle(data_set:)
      fetch_tmas_counts.call(start_date:) do |response|
        response
          .bind { |branches| Traverse.new.call(branches) { |branch| to_airtable_hashes.call(branch) } }
          # The Airtable API only can handle 10 records at a time
          .fmap { |all_data| all_data.flatten.each_slice(10).map { { records: it }.to_json } }
          .bind { |batches| send_batches_to_airtable.call(batches) }
        # .bind { update next day to process }
        # .or { handle the failure, no matter where in the process it came from, break }
      end

      data_set
    end

    def send_batches_to_airtable
      SendBatchesToAirtable.new(airtable_client)
    end

    def airtable_client
      @airtable_client ||= airtable_client_class.new
    end

    def fetch_tmas_counts
      @fetch_tmas_counts ||= fetch_tmas_counts_class.new
    end

    def post_to_airtable
      @post_to_airtable ||= post_to_airtable_class.new
    end

    def to_airtable_hashes
      @to_airtable_hashes = ToAirtableHashes.new
    end

    def start_date
      next_date_class
        .next(category)
        # The first day we started using TMAS
        .value_or(Date.parse('2025-09-01'))
    end

    attr_reader :airtable_client_class, :fetch_tmas_counts_class, :next_date_class
  end
end
