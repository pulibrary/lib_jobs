# frozen_string_literal: true
class DataSet < ApplicationRecord
  def self.filter_by_date(report_date:, query_context:)
    return query_context if report_date.blank?
    start_report_date = Time.zone.parse(report_date).midnight
    end_report_date = start_report_date.at_end_of_day
    query_context.where(report_time: start_report_date..end_report_date)
  end

  def self.filter_by_time(report_time:, query_context:)
    return query_context if report_time.blank?
    report_time = Time.zone.parse(report_time)
    query_context.where(report_time: report_time)
  end
end
