# frozen_string_literal: true
class LibJob
  def initialize(category: nil)
    @category = category
  end

  def run
    data_set = handle(data_set: DataSet.new(category:))
    data_set.report_time ||= Time.zone.now
    data_set.save
    data_set.status
  end

  def read_most_recent_report
    report_data = ''
    File.open(most_recent_dataset.data_file) do |file|
      report_data = file.read
    end
    report_data
  end

  def most_recent_dataset
    data_set = DataSet.where(category: @category)
                      .order(created_at: :desc)
                      .limit(1)
                      .first
    return unless data_set && File.exist?(data_set.data_file)

    data_set
  end

  # start of the last successful run
  def last_successful_run_time
    DataSet.where(category:, status: true).order(report_time: :desc).pick(:report_time)
  end

  # Expect subclass to implement handle to do the actual data set creation
  # def handle(data_set:)
  # end

  def category
    @category || raise('You must supply a category, either as an argument to the initializer, or by overriding the #category method')
  end
end
