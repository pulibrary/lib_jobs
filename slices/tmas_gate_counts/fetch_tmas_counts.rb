# frozen_string_literal: true

module TMASGateCounts
  # This class is responsible for fetching gate counts from the TMAS system
  # for all the desired days and locations
  class FetchTMASCounts
    include Dry::Monads[:result]

    include Deps['princeton_timezone', 'tmas_locations', 'shared.traverse', client: 'tmas_client']

    # Yields a Success([String]) for each day's statistics (or Failure() if there was a problem)
    def call(start_date:, end_date: princeton_timezone.yesterday, locations: tmas_locations.keys)
      (start_date..end_date).each do |date|
        response = traverse.call(locations) { |location| client.fetch_data(date:, location:) }
        yield response, date
        break if response.failure?
      end
    end
  end
end
