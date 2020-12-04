# frozen_string_literal: true
require 'csv'

class StaffDirectoryDifference
  attr_reader :new_report, :old_report, :report_time
  def initialize(new_report:, old_report:, report_time: today)
    @new_report = new_report
    @old_report = old_report
    @report_time = report_time
  end

  def ids
    data_sets = DataSet.where(report_time: report_time, category: "StaffDirectoryRemoved")
    if data_sets.empty?
      calculate_removed_ids
    else
      data_sets.first.data.split(',')
    end
  end

  private

  def today
    DateTime.now.midnight
  end

  def calculate_removed_ids
    old_ids = parse_ids(report: old_report)
    new_ids = parse_ids(report: new_report)
    removed_ids = old_ids - new_ids
    added_ids = new_ids - old_ids
    DataSet.create(report_time: today, data: removed_ids.join(","), data_file: nil, category: "StaffDirectoryRemoved")
    DataSet.create(report_time: today, data: added_ids.join(","), data_file: nil, category: "StaffDirectoryAdded")
    removed_ids
  end

  def parse_ids(report:)
    ids = []
    people_data = ::CSV.new(report, headers: true).read
    people_data.each do |row|
      netid = row['NetID']
      ids << netid if netid.present?
    end
    ids
  end
end
