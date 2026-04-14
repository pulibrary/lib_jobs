# frozen_string_literal: true
module TMASGateCounts
  class Job < LibJob
    def initialize(fetch_tmas_counts_class: FetchTMASCounts, next_date_class: NextDateToProcess)
      @fetch_tmas_counts_class = fetch_tmas_counts_class
      @next_date_class = next_date_class
      super(category: 'TMASGateCounts')
    end

      private

    def handle(data_set:)
      fetch_tmas_counts_class.new.call(start_date:)

      data_set
    end

    def start_date
      next_date_class
        .next(category)
        # The first day we started using TMAS
        .value_or(Date.parse('2025-09-01'))
    end

    attr_reader :fetch_tmas_counts_class, :next_date_class
  end
end
