# frozen_string_literal: true
module TMASGateCounts
  class AirtableClient
    include Dry::Monads[:result]

    def initialize(env: ENV)
      @env = env
    end

    def call(request_class: Net::HTTP::Post, json:)
      request = request_class.new(uri, { 'Authorization' => "Bearer #{env['PEOPLE_COUNTER_AIRTABLE_TOKEN']}", 'Content-Type' => 'application/json' })
      request.body = json
      response = Net::HTTP.start(uri.hostname, uri.port, { use_ssl: true }) do |http|
        http.request(request)
      end
      case response.code
      in '200'
        Success(response.body)
      else
        error = "Got response #{response.code} from the Airtable API while attempting #{request_class}"
        Rails.logger.error error
        Failure(error)
      end
    end

    BASE_ID = 'appAqHrmsuH7VsZOB'
    TABLE_ID = 'tblLkWS3cZh8YqlgN'

    private

    attr_reader :env

    def uri
      @uri ||= URI.parse("https://api.airtable.com/v0/#{BASE_ID}/#{TABLE_ID}")
    end
  end
end
