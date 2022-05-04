# frozen_string_literal: true
class DataSetList
  attr_reader :data_sets
  delegate :each, to: :data_sets

  def initialize(data_sets)
    @data_sets = data_sets
  end

  def categories
    DataSet.select(:category).distinct.map(&:category)
  end
end
