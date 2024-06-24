# frozen_string_literal: true
module AirTableStaff
  # This class is responsible for running and
  # recording the results of Airtable-based
  # CSV file generation
  class StaffListJob < LibJob
    def initialize(filename: nil)
      super(category: 'AirTableStaffDirectory')
      @report_filename = filename if filename
    end

    private

    def handle(data_set:)
      if Flipflop.air_table_staff_list?
        return most_recent_dataset if most_recent_dataset && recent_enough?(most_recent_dataset&.data_file)
        write_csv_to_disk
        data_set.data_file = report_filename
      else
        data_set.data = 'Airtable-based staff list is typically scheduled for this time, but it is turned off.  Go to /features to turn it back on.'
      end
      data_set.report_time = Time.zone.now
      data_set
    end

    def write_csv_to_disk
      File.open(report_filename, 'w') { |file| file.write(CSVBuilder.new.to_csv) }
    end

    def report_filename
      @report_filename ||= begin
        date_str = Time.zone.now.strftime('%Y%m%d%H%M')
        File.join(Rails.configuration.staff_directory['report_directory'], "library_staff_#{date_str}.csv")
      end
    end

    def recent_enough?(filename)
      File.mtime(filename) > 2.hours.ago
    end
  end
end
