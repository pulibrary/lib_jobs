# frozen_string_literal: true
# This class is responsible for converting an XML string of TMAS data to
# an array of hashes for use in Airtable
module TMASGateCounts
  class ToAirtableHashes
    include Dry::Monads[:result]
    def call(tmas_xml)
      Rails.logger.debug { "Converting #{tmas_xml} into airtable json" }
      in_summaries = entries(tmas_xml).select { |entry| sensor(entry) == :in }.map { |entry| HourlySummary.from_entry(entry) }
      out_summaries = entries(tmas_xml).select { |entry| sensor(entry) == :out }.map { |entry| HourlySummary.from_entry(entry) }
      Success(
        in_summaries.zip(out_summaries)
          .map { |summaries| CombineSensorData.new.call(summaries) }
      )
    end

    private

    def entries(tmas_xml)
      Nokogiri::XML(tmas_xml).css('data')
    end

    def sensor(entry)
      if entry.attr('storeId').include? ' - Out|'
        :out
      else
        :in
      end
    end
  end
end
