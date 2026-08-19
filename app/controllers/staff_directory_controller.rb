# frozen_string_literal: true
class StaffDirectoryController < ApplicationController
  def pul_staff_report
    job = AirTableStaff::StaffListJob.new
    job.run
    respond_to do |format|
      format.csv { send_data job.read_most_recent_report, filename: "pul-staff-report.csv" }
    end
  end
end
