# frozen_string_literal: true

module TMASGateCounts
  # This struct represents an hourly summary of gate counts from a single sensor (could be IN or OUT sensor)
  HourlySummary = Data.define(:location, :time, :gate_count)
end
