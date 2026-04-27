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
      fetch_tmas_counts.call(start_date:)
                       .bind do |responses|
                         responses.each do |response|
                           to_airtable_hashes
                             .call(response)
                             .bind { send_batches_to_airtable.call(batches) }
                         end
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
