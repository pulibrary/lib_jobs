# frozen_string_literal: true
module TMASGateCounts
  class AirtableClient
    include Dry::Monads[:result]

    def initialize(env: ENV)
      @env = env
    end

    def call(request_class: Net::HTTP::Post, json: nil, uri_builder: AirtableClient.default_uri_builder)
      uri = uri_builder.call(BASE_ID, TABLE_ID)
      request = request_class.new(uri, { 'Authorization' => "Bearer #{env['PEOPLE_COUNTER_AIRTABLE_TOKEN']}", 'Content-Type' => 'application/json' })
      request.body = json if json
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

    def self.default_uri_builder
      ->(base_id, table_id) { URI.parse("https://api.airtable.com/v0/#{base_id}/#{table_id}") }
    end

    def self.delete_uri_builder(ids)
      query_string = ids.map { |id| "records[]=#{id}" }.join('&')
      ->(base_id, table_id) { URI.parse("https://api.airtable.com/v0/#{base_id}/#{table_id}?#{query_string}") }
    end

    BASE_ID = 'appAqHrmsuH7VsZOB'
    TABLE_ID = 'tblLkWS3cZh8YqlgN'

    private

    attr_reader :env
  end
end
