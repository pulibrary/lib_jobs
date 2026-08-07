# frozen_string_literal: true
module TMASGateCounts
  # This class is responsible for requesting the
  # desired data from TMAS
  class TMASClient
    include Dry::Monads[:result]
    include Deps['settings', 'tmas_client.wait_for_rate_limit']

    def fetch_data(date:, location:)
      Rails.logger.debug { "requesting from TMAS for #{date} in #{location}" }
      wait_for_rate_limit.call
      uri = URI "https://www.smssoftware.net/tms/manTrafExp?fromDate=#{date.strftime('%m/%d/%Y')}&toDate=#{date.strftime('%m/%d/%Y')}&interval=60&hours=0&reqType=tds&apiKey=#{settings.tmas_api_key}&locationId=#{location}"
      response = Net::HTTP.get_response uri
      if response.code == '200'
        Success(response.body)
      elsif response.code == '400'
        Failure("Forbidden access: make sure the API key and location code (#{location}) are correct")
      else
        Failure("Got response #{response.code} from the TMAS API")
      end
    end
  end
end
