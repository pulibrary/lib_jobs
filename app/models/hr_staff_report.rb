# frozen_string_literal: true

require 'csv'

class HrStaffReport
  attr_reader :csv

  delegate :each, :first, :count, to: :people

  def initialize(hr_data: File.new(Rails.configuration.staff_directory['hr_staff_report_location'], encoding: "UTF-16"))
    @csv = ::CSV.new(hr_data, col_sep: "\t", headers: true)
  end

  def people
    @people ||= csv.read
  end

  def last
    people[count - 1]
  end
end
