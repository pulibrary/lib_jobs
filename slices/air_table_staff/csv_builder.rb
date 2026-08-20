# frozen_string_literal: true
require 'csv'
module AirTableStaff
  # This class is responsible for creating a CSV out of the
  # data from Airtable
  class CSVBuilder
    include Deps['staff_directory_mapping']

    def call
      @csv ||= CSV.generate do |csv|
        # Add the headers...
        csv << staff_directory_mapping.csv_headers

        # Then add the data
        AirTableStaff::RecordList.new.to_a.each do |record|
          csv << record.to_a
        end
      end
    end
  end
end
