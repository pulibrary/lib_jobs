# frozen_string_literal: true

module TMASGateCounts
  # This struct represents an hourly summary of gate counts from a single sensor (could be IN or OUT sensor)
  HourlySummary = Struct.new(:location, :time, :count) do
    # From an XML entry
    def self.from_entry(entry)
      library_code = entry.attr('storeId').partition('|').first.upcase
      HourlySummary.new(
          Slice['tmas_locations'][library_code],
          Slice['princeton_timezone'].parse(entry.attr('trafficDate')),
          entry.attr('trafficValue').gsub(/\.\d+/, '').to_i
        )
    end
  end
end
