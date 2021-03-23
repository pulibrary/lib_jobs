# frozen_string_literal: true

require 'csv'

class HrStaffReport
  delegate :each, :first, :count, to: :people

  def self.hr_staff_report_location
    Rails.configuration.staff_directory['hr_staff_report_location']
  end

  def self.default_hr_data
    File.new(hr_staff_report_location, encoding: "UTF-16")
  rescue StandardError => error
    Rails.logger.error("Failed to open the HR staff report file: #{error}")
    nil
  end

  def initialize(hr_data: nil)
    @hr_data = hr_data || self.class.default_hr_data
  end

  def people
    return [] if csv.nil?

    @people ||= csv.read
  end

  def last
    people[count - 1]
  end

  def csv
    return if @hr_data.nil?
    @csv ||=
      begin
        ::CSV.new(@hr_data, col_sep: "\t", headers: true)
      end
  end
end
