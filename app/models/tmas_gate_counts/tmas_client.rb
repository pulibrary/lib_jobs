# frozen_string_literal: true
module TMASGateCounts
  # This class is responsible for requesting the
  # desired data from TMAS
  class TMASClient
    include Dry::Monads[:result]

    def initialize(
      api_key: ENV['TMAS_API_KEY'],
      # The TMAS documentation says:
      # "The T.M.A.S. Web API has a rate limit of one call every two seconds."
      wait_for_rate_limit: ->() { sleep 2 }
    )
      @api_key = api_key
      @wait_for_rate_limit = wait_for_rate_limit
    end

    def fetch_data(date:, location:)
      wait_for_rate_limit.call
      uri = URI "https://www.smssoftware.net/tms/manTrafExp?fromDate=#{date.strftime('%m/%d/%Y')}&toDate=#{date.strftime('%m/%d/%Y')}&interval=60&hours=0&reqType=td&apiKey=#{api_key}&locationId=#{location}"
      response = Net::HTTP.get_response uri
      if response.code == '200'
        Success(response.body)
      elsif response.code == '400'
        Failure("Forbidden access: make sure the API key and location code (#{location}) are correct")
      else
        Failure("Got response #{response.code} from the TMAS API")
      end
    end

      private

    attr_reader :api_key, :wait_for_rate_limit
  end
end
