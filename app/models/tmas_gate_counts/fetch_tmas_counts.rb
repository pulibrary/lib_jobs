# frozen_string_literal: true

module TMASGateCounts
  # This class is responsible for fetching gate counts from the TMAS system
  # for all the desired days and locations
  class FetchTMASCounts
    include Dry::Monads[:result]

    def initialize(client: TMASClient.new)
      @client = client
    end

    # Yields a Success([String]) for each day's statistics (or Failure() if there was a problem)
    def call(start_date:, end_date: PRINCETON_TIMEZONE.yesterday, locations: TMAS_LOCATIONS.keys)
      (start_date..end_date).each do |date|
        response = Traverse.new.call(locations) { |location| client.fetch_data(date:, location:) }
        yield response
        break if response.failure?
      end
    end

    private

    attr_reader :client
  end
end
