# frozen_string_literal: true
class StaffDirectoryController < ApplicationController
  class_attribute :finance_report, default: {}

  def index
    finance_report = WebStaff::FinanceReport.new
    hr_report = WebStaff::HrStaffReport.new
    generator = WebStaff::StaffDirectoryGenerator.new(finance_report:, hr_report:)
    respond_to do |format|
      format.csv { send_data generator.today, filename: "staff-directory.csv" }
    end
  end

  def removed
    today_report = File.new(WebStaff::StaffDirectoryGenerator.report_filename)
    yesterday_report = File.new(WebStaff::StaffDirectoryGenerator.yesterday_filename)
    differ = WebStaff::StaffDirectoryDifference.new(new_report: today_report, old_report: yesterday_report)
    respond_to do |format|
      format.text { send_data differ.ids.join(","), filename: "removed-staff.txt" }
    end
  end
end
