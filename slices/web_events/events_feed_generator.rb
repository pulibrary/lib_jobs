# frozen_string_literal: true
# auto_register: false

class WebEvents::EventsFeedGenerator < LibJob
  include Dry::Monads[:result]
  def initialize(create_csv: WebEvents::Slice['operations.create_csv'])
    @create_csv = create_csv
    super(category: 'EventsFeed')
  end

  private

  attr_reader :create_csv

  def handle(data_set:)
    return most_recent_dataset if most_recent_dataset && recent_enough?(most_recent_dataset&.data_file)
    results = create_csv.call
    RecentJobStatus.register job: 'EventsFeed', status: results

    case results
    in Success(filename)
      data_set.data_file = filename
    else
    end
    data_set.report_time = Time.zone.now
    data_set
  end

  def recent_enough?(filename)
    File.mtime(filename) > 1.hour.ago
  end
end
