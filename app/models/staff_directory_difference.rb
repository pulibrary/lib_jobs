# frozen_string_literal: true
require 'csv'

class StaffDirectoryDifference
  attr_reader :new_report, :old_report
  def initialize(new_report:, old_report:)
    @new_report = new_report
    @old_report = old_report
  end

  def ids
    old_ids = parse_ids(report: old_report)
    new_ids = parse_ids(report: new_report)
    old_ids - new_ids
  end

  private

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
