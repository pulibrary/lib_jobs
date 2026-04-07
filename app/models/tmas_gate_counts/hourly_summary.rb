# frozen_string_literal: true
TMAS_LOCATIONS = {
  'ARCH0000' => 'Architecture',
  'ANXN0000' => 'Commons',
  'COTSEN' => 'Cotsen',
  'PLLR0000' => 'East Asian Library',
  'LEWIS' => 'Lewis and Engineering',
  'RHED0000' => 'Marquand',
  'MEND0000' => 'Mendel',
  'SLES0000' => 'Stokes Library'
}.freeze

PRINCETON_TIMEZONE = ActiveSupport::TimeZone.new('Eastern Time (US & Canada)')

module TMASGateCounts
  # This struct represents an hourly summary of gate counts
  HourlySummary = Struct.new(:location, :time, :count) do
    def to_h
      { columns[:location] => location, columns[:time] => time.iso8601, columns[:count] => count }
    end

    # From an XML entry
    def self.from_entry(entry)
      HourlySummary.new(
          TMAS_LOCATIONS[entry.attr('storeId')],
          PRINCETON_TIMEZONE.parse(entry.attr('trafficDate')),
          entry.attr('trafficValue').gsub(/\.\d+/, '').to_i
        )
    end

      private

    # Airtable uses unique ids for each column which should persist even if somebody renames
    # the column.
    # These column identifiers can be found at https://airtable.com/appv7XA5FWS7DG9oe/api/docs
    def columns
      { location: :fld5OFSWCZzeQb1Dq, time: :fldemkioYkKtAfesm, count: :fldwUTBK3mvfpN3Y8 }
    end
  end
end
