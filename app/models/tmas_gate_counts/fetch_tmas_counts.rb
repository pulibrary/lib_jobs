# frozen_string_literal: true

module TMASGateCounts
  class FetchTMASCounts
    include Dry::Monads[:result]

    def initialize(client: TMASClient.new)
      @client = client
    end

    # Returns Success([String]) or Failure
    def call(first:, last: 1.day.ago, locations: TMAS_LOCATIONS.keys)
      responses = traverse(locations) { |location| client.fetch_data(date: first, location:) }
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

    # `traverse` runs the provided block on the array.
    # As long as the block returns Success, it behaves
    # like Array#map, returning every value wrapped in
    # Success(Array).
    # As soon as it hits Failure, it will return the
    # Failure and stop processing the array.
    def traverse(array)
      array.reduce(Success([])) do |accumulator, el|
        result = yield(el)
        case result
        when Success
          accumulator.fmap { |accumulated| accumulated.push(result.value!) }
        else
          break result
        end
      end
    end
  end
end
