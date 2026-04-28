# frozen_string_literal: true
module TMASGateCounts
  class Job < LibJob
    include Dry::Monads[:result]

    def initialize(
      fetch_tmas_counts_class: FetchTMASCounts,
      next_date_class: NextDateToProcess,
      send_batches_to_airtable_class: SendBatchesToAirtable
    )
      @fetch_tmas_counts_class = fetch_tmas_counts_class
      @next_date_class = next_date_class
      @send_batches_to_airtable_class = send_batches_to_airtable_class
      super(category: 'TMASGateCounts')
    end

    private

    def handle(data_set:)
      fetch_tmas_counts.call(start_date:) do |response, date|
        response
          .bind { |branches| Traverse.new.call(branches) { |branch| to_airtable_hashes.call(branch) } }
          # The Airtable API only can handle 10 records at a time
          .fmap { |all_data| all_data.flatten.each_slice(10).map { { records: it }.to_json } }
          .bind { |batches| send_batches_to_airtable.call(batches) }
          .bind { |_airtable_ids| next_date_class.set(job: category, next: (date + 1.day)) }
          .or do |failure|
            handle_failure(failure)
            return data_set
          end
      end

      RecentJobStatus.register(job: category, status: Success())
      data_set
    end

    def handle_failure(failure)
      TMASAirtableErrorMailer.error_notification(failure)
      Honeybadger.notify("#{category}: #{failure}")
      RecentJobStatus.register(job: category, status: Failure(failure))
    end

    def send_batches_to_airtable
      send_batches_to_airtable_class.new
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

    attr_reader :fetch_tmas_counts_class, :next_date_class, :send_batches_to_airtable_class
  end
end
