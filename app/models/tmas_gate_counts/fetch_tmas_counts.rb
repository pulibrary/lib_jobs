# frozen_string_literal: true

module TMASGateCounts
  class FetchTMASCounts
    include Dry::Monads[:result]

    def initialize(client: TMASClient.new)
      @client = client
    end

    # Returns Success([String]) or Failure
    def call(first:, last: 1.day.ago, locations: TMAS_LOCATIONS.keys)
      responses = Traverse.new.call(locations) { |location| client.fetch_data(date: first, location:) }
      if responses.success && first < last
        responses.and call(
            first: first + 1.day,
            last:,
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
