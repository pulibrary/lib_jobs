# frozen_string_literal: true
require 'csv'

module WebStaff
  class StaffDirectoryGenerator < LibJob
    def self.report_filename(date: Time.zone.today)
      date_str = date.strftime('%Y%m%d')
      File.join(Rails.configuration.staff_directory['report_directory'], "#{Rails.configuration.staff_directory['report_name']}_#{date_str}.csv")
    end

    def self.yesterday_filename
      report_filename(date: Time.zone.yesterday)
    end

    attr_reader :finance_report, :hr_report, :report_filename
    def initialize(finance_report:, hr_report:)
      super(category: "StaffDirectory")
      @finance_report = finance_report
      @hr_report = hr_report
      @report_filename = self.class.report_filename
    end

    def today
      data_sets = DataSet.where(category: category, report_time: Time.zone.today.midnight)
      run if data_sets.empty? || !File.exist?(data_sets.first.data_file)
      read_report
    end

    private

    def handle(data_set:)
      File.open(report_filename, "w") do |file|
        file.write(report)
      end
      data_set.report_time = Time.zone.now.midnight
      data_set.data_file = report_filename
      data_set
    end

    def report
      people = []
      hr_report.each do |person|
        staff = StaffMember.new(person)
        people << staff.hash
      end
      generate_csv(people) unless people.empty?
    end

    def read_report
      report_data = ''
      File.open(report_filename) do |file|
        report_data = file.read
      end
      report_data
    end

    def generate_csv(people)
      return if people.empty?

      unquoted = unquoted_columns(people.first.keys)
      quote_col2 = lambda do |field, fieldinfo|
        # fieldinfo has a line- ,header- and index-method
        if field.present? && (fieldinfo.line == 1 || !unquoted.include?(fieldinfo.index))
          '"' + field + '"'
        else
          field
        end
      end
      CSV.generate(write_converters: [quote_col2], quote_char: "") do |csv|
        csv << people.first.keys
        people.each { |person| csv << person.values }
      end
    end

    def unquoted_columns(keys)
      unquoted = ["idStaff", "StartDate", "StaffSort", "UnitSort", "DeptSort", "FireWarden", "BackupFireWarden"]
      columns = []
      keys.each_with_index { |key, index| columns << index if unquoted.include?(key) }
      columns
    end
  end
end
