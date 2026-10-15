# frozen_string_literal: true

module TMASGateCounts
  class Job < LibJob
    include Deps['fetch_tmas_counts', 'mailers.error_notification', 'shared.repos.next_date_to_process_repo', 'send_batches_to_airtable', 'shared.traverse']
    include Dry::Monads[:result]

    def category = 'TMASGateCounts'

    private

    def handle(data_set:)
      fetch_tmas_counts.call(start_date:) do |response, date|
        response
          .bind { |branches| traverse.call(branches) { |branch| to_airtable_hashes.call(branch) } }
          # The Airtable API only can handle 10 records at a time
          .fmap { |all_data| all_data.flatten.each_slice(10).map { { records: it }.to_json } }
          .bind { |batches| send_batches_to_airtable.call(batches) }
          .bind { |_airtable_ids| next_date_to_process_repo.set(job: category, next: (date + 1.day)) }
          .or do |failure|
            handle_failure(failure)
            return data_set
          end
      end

      RecentJobStatus.register(job: category, status: Success())
      data_set
    end

    def handle_failure(failure)
      error_notification.deliver(failure:)
      Honeybadger.notify("#{category}: #{failure}")
      RecentJobStatus.register(job: category, status: Failure(failure))
    end

    def post_to_airtable
      @post_to_airtable ||= post_to_airtable_class.new
    end

    def to_airtable_hashes
      @to_airtable_hashes = ToAirtableHashes.new
    end

    def start_date
      next_date_to_process_repo
        .next(job: category)
        # The first day we started using TMAS
        .value_or(Date.parse('2025-09-01'))
    end
  end
end
