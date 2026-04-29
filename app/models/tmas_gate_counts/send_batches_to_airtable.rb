# frozen_string_literal: true
module TMASGateCounts
  # This class is responsible for sending batches of gate count data to Airtable,
  # and rolling back to a clean state if there was a problem
  class SendBatchesToAirtable
    include Dry::Monads[:result]

    def initialize(client = AirtableClient.new)
      @client = client
    end

    def call(batches)
      ids = batches.reduce([]) do |accumulator, batch|
        response = client.call(json: batch)
        case response
        in Success
          accumulator + JSON.parse(response.value!, symbolize_names: true)[:records]&.map { it[:id] }
        in Failure
          rollback(accumulator)
          return response
        end
      end
      Rails.logger.info("Sent #{ids.count} records to airtable")
      Success(ids)
    end

      private

    attr_reader :client

    # Delete all of the provided IDs, so that Airtable is not left in a situation of
    # partial data
    def rollback(ids)
      # Airtable can only delete 10 ids at a time
      ids.each_slice(10) do |id_batch|
        client.call(
      request_class: Net::HTTP::Delete,
      uri_builder: TMASGateCounts::AirtableClient.delete_uri_builder(id_batch)
    )
      end
    end
  end
end
