# frozen_string_literal: true

require 'csv'

module WebDatabaseList
  # This job is responsible for creating a CSV file of research databases,
  # using data from Libguides
  class DatabasesFeed < LibJob
    include Deps['database_to_csv', 'libguides_assets_feed', 'report_filename']

    def category = 'DatabasesFeed'

    private

    def handle(data_set:)
      return most_recent_dataset if most_recent_dataset && recent_enough?(most_recent_dataset&.data_file)

      filename = write_csv_to_disk
      data_set.report_time = Time.zone.now
      data_set.data_file = filename
      data_set
    end

    def write_csv_to_disk
      filename = report_filename.call
      CSV.open(Pathname.new(filename), 'wb') do |csv|
        csv << database_to_csv.field_names
        libguides_assets_feed.fetch.each do |database|
          if database['friendly_url'].blank?
            Rails.logger.warn("Skipping database without friendly_url. Database id: #{database['id']}, Database name: #{database['name']}")
            next
          end
          csv << database_to_csv.call(database)
        end
      end
      filename
    end

    def recent_enough?(filename)
      File.mtime(filename) > 2.hours.ago
    end
  end
end
