# frozen_string_literal: true
# This class is responsible for converting an XML string of TMAS data to
# an array of json strings for use in Airtable
module TMASGateCounts
  class ToAirtableJson
    include Dry::Monads[:result]
    def call(tmas_xml)
      Success(
        entries(tmas_xml)
            .map { |entry| HourlySummary.from_entry(entry).to_h }
            .then { |summaries| as_grouped_json(summaries) }
      )
    end

    private

    def entries(tmas_xml)
      Nokogiri::XML(tmas_xml).css('data')
    end

    # The Airtable API can only handle 10 records at once, so
    # we group our JSON into chunks of 10 records
    def as_grouped_json(original)
      original.each_slice(10).map { it.to_json }
    end
  end
end
