# frozen_string_literal: true
require 'csv'

module WebDatabaseList
  class DatabasesFeed < LibJob
    def initialize(database_list: nil, filename: nil)
      super(category: "DatabasesFeed")
      @database_list = database_list || LibguidesAssetsFeed.new.fetch
      @report_filename = filename || report_filename
    end

    private

    def handle(data_set:)
      return most_recent_dataset if most_recent_dataset && recent_enough?(most_recent_dataset&.data_file)
      write_csv_to_disk
      data_set.report_time = Time.zone.now
      data_set.data_file = report_filename
      data_set
    end

    def write_csv_to_disk
      CSV.open(Pathname.new(@report_filename), 'wb') do |csv|
        csv << Database.field_names
        @database_list.each do |database|
          if database["friendly_url"].blank?
            Rails.logger.warn("Skipping database without friendly_url. Database id: #{database['id']}, Database name: #{database['name']}")
            next
          end
          csv << Database.new(database).to_csv_row
        end
      end
    end

    def report_filename
      date_str = Time.zone.now.strftime('%Y%m%d%H%M')
      File.join(Rails.configuration.staff_directory['report_directory'], "library_databases_#{date_str}.csv")
    end

    def recent_enough?(filename)
      File.mtime(filename) > 2.hours.ago
    end
  end
end
