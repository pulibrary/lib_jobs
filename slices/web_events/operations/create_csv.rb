# frozen_string_literal: true

require 'dry/operation'
require 'open-uri'
require 'csv'

module WebEvents
  module Operations
    # This operation is responsible for creating a CSV of events using data in
    # the ICAL format from LibCal
    class CreateCSV < Dry::Operation
      include Deps['csv_row_from_ical']

      def call(filename: report_filename)
        events = step fetch_events
        rows = step create_rows(events)
        step write_to_csv(rows, filename)
        filename
      end

      private

      def fetch_events
        events = WebEvents::Slice['libcal_url'].open do |file|
          Icalendar::Calendar.parse(file).first.events
        end
        Success(events)
      end

      def create_rows(events)
        Success(events.map { |event| csv_row_from_ical.call(event) })
      end

      def write_to_csv(rows, filename)
        CSV.open(Pathname.new(filename), 'wb') do |csv|
          csv << csv_headers
          rows.each do |row|
            csv << row
          end
        end
        Success(filename)
      end

      def csv_headers = ['guid', 'title', 'description', 'location', 'start_time', 'end_time', 'url', 'categories']

      def report_filename
        File.join(Rails.configuration.staff_directory['report_directory'], "library_events_#{date_str}.csv")
      end

      def date_str = Time.zone.now.strftime('%Y%m%d%H%M')
    end
  end
end
