# frozen_string_literal: true
# This class is responsible for converting an XML string of TMAS data to
# an array of json strings for use in Airtable
module TMASGateCounts
  class ToAirtableJson
    include Dry::Monads[:result]
    def call(tmas_xml)
      Rails.logger.debug { "Converting #{tmas_xml} into airtable json" }
      Success(
        entries(tmas_xml)
            .map { |entry| { fields: HourlySummary.from_entry(entry).to_h } }
            # The Airtable API can only handle 10 records at once, so
            # we group our JSON into chunks of 10 records
            .then { |summaries| summaries.each_slice(10).to_a }
      )
    end

    private

    def entries(tmas_xml)
      Nokogiri::XML(tmas_xml).css('data')
    end
  end
end
