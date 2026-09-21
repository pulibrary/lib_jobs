# frozen_string_literal: true
module TMASGateCounts
  # This class is responsible for combining data from two sensors into
  # a single hash.
  class CombineSensorData
    COLUMNS = { location: :fld5OFSWCZzeQb1Dq, time: :fldemkioYkKtAfesm, in_count: :fldwUTBK3mvfpN3Y8, out_count: :fldat8beQUOCWvdjm }.freeze

    # summaries is a 2-element array where:
    #   * the first element is data from the IN sensor
    #   * the second element is data from the OUT sensor
    def call(summaries)
      { fields: {
        COLUMNS[:location] => summaries.first.location,
        COLUMNS[:time] => summaries.first.time.iso8601,
        COLUMNS[:in_count] => summaries.first.count,
        COLUMNS[:out_count] => summaries.second.count
      } }
    end
  end
end
