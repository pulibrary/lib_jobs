# frozen_string_literal: true
require 'open-uri'
require 'csv'

class WebEvents::EventsFeedGenerator < LibJob
  def initialize(filename: nil)
    super(category: 'EventsFeed')
    @report_filename = filename || report_filename
  end

  def events
    @events = URI.open(WebEvents::LibcalUrl.new.to_s) do |file|
      raw_events = Icalendar::Calendar.parse(file).first.events
      raw_events.map { |event| WebEvents::Event.new(event) }
    end
  end

  def read_most_recent_report
    report_data = ''
    File.open(most_recent_dataset.data_file) do |file|
      report_data = file.read
    end
    report_data
  end

  private

  def handle(data_set:)
    return most_recent_dataset if most_recent_dataset && recent_enough?(most_recent_dataset&.data_file)
    write_csv_to_disk
    data_set.report_time = Time.zone.now.midnight
    data_set.data_file = report_filename
    data_set
  end

  def write_csv_to_disk
    CSV.open(Pathname.new(@report_filename), 'wb') do |csv|
      csv << csv_headers
      events.each do |event|
        csv << event.to_a
      end
    end
  end

  def csv_headers
    ['guid', 'title', 'description', 'location', 'start_time',
     'end_time', 'url', 'categories']
  end

  def report_filename
    date_str = Time.zone.now.strftime('%Y%m%d%H%M')
    File.join(Rails.configuration.staff_directory['report_directory'], "library_events_#{date_str}.csv")
  end

  def most_recent_dataset
    data_set = DataSet.where(category: 'EventsFeed')
                      .order(created_at: :desc)
                      .limit(1)
                      .first
    return unless data_set && File.exist?(data_set.data_file)

    data_set
  end

  def recent_enough?(filename)
    File.mtime(filename) > 1.hour.ago
  end
end
