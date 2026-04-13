# frozen_string_literal: true

module TMASGateCounts
  class FetchTMASCounts
    include Dry::Monads[:result]

    def initialize(client: TMASClient.new)
      @client = client
    end

    # Returns Success([String]) or Failure
    def call(start_date:, end_date: 1.day.ago, locations: TMAS_LOCATIONS.keys)
      responses = Traverse.new.call(locations) { |location| client.fetch_data(date: start_date, location:) }
      if responses.success && start_date < end_date
        responses.and call(
            start_date: start_date + 1.day,
            end_date:,
            locations:
          ) do |x, y|
            x + y
          end
      else
        responses
      end
    end

    private

    attr_reader :client
  end
end
