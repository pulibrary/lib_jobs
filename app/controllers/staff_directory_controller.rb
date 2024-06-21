# frozen_string_literal: true
class StaffDirectoryController < ApplicationController
  def index
    hr_report = WebStaff::HrStaffReport.new
    generator = WebStaff::StaffDirectoryGenerator.new(hr_report:)
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

  def pul_staff_report
    if Flipflop.air_table_staff_list?
      job = AirTableStaff::StaffListJob.new
      job.run
      respond_to do |format|
        format.csv { send_data job.read_most_recent_report, filename: "pul-staff-report.csv" }
      end
    else
      render plain: 'Airtable-based staff list is turned off.  Go to /features to turn it back on.'
    end
  end
end
