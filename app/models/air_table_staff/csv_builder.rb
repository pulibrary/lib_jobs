# frozen_string_literal: true

module AirTableStaff
  # This class is responsible for creating a CSV out of the
  # data from Airtable
  class CSVBuilder
    def to_csv
      @csv ||= CSV.generate do |csv|
        # Add the headers...
        csv << StaffDirectoryMapping.new.to_a

        # Then add the data
        AirTableStaff::RecordList.new.to_a.each do |record|
          csv << record.to_a
        end
      end
    end
  end
end
