# frozen_string_literal: true
class StaffDirectoryController < ApplicationController
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
