# frozen_string_literal: true

module TMASGateCounts
  # Summarize an XML entry
  class SummarizeEntry
    include Deps['princeton_timezone', 'tmas_locations']

    def call(entry)
      library_code = entry.attr('storeId').partition('|').first.upcase
      HourlySummary.new(
        tmas_locations[library_code],
        princeton_timezone.parse(entry.attr('trafficDate')),
        entry.attr('trafficValue').gsub(/\.\d+/, '').to_i
      )
    end
  end
end
