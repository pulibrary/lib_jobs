# frozen_string_literal: true
class LibJob
  attr_reader :category
  def initialize(category:)
    @category = category
  end

  def run
    data_set = handle(data_set: DataSet.new(category: category))
    data_set.report_time ||= Time.zone.now
    data_set.save
    data_set.status
  end

  # Expect subclass to implement handle to do the actual data set creation
  # def handle(data_set:)
  # end
end
