# frozen_string_literal: true

class StaffDirectoryGenerator
  def self.report_filename
    File.join(Rails.configuration.staff_directory['report_directory'], Rails.configuration.staff_directory['report_name'])
  end

  def self.yesterday_filename
    "#{report_filename}_#{Date.yesterday.strftime('%Y%m%d')}"
  end

  attr_reader :finance_report, :hr_report
  def initialize(finance_report:, hr_report:)
    @finance_report = finance_report
    @hr_report = hr_report
  end

  def today
    report_filename = self.class.report_filename
    yesterday_filename = self.class.yesterday_filename

    need_to_generate = !File.exist?(yesterday_filename)
    report_exists = File.exist?(report_filename)
    File.rename(report_filename, yesterday_filename) if report_exists && need_to_generate

    if need_to_generate || !report_exists
      create_report(report_filename)
    else
      read_report(report_filename)
    end
  end

  def report
    people = []
    hr_report.each do |person|
      finance_data = finance_report.report(employee_id: person["EID"])
      people << create_person_hash(finance_person: finance_data, hr_person: person)
    end
    generate_csv(people)
  end

  private

  def create_report(report_filename)
    report_data = ''
    File.open(report_filename, "w") do |file|
      report_data = report
      file.write(report_data)
    end
    report_data
  end

  def read_report(report_filename)
    report_data = ''
    File.open(report_filename) do |file|
      report_data = file.read
    end
    report_data
  end

  def create_person_hash(finance_person:, hr_person:)
    person = fill_in_with_hr(finance_person: finance_person, hr_person: hr_person)
    person["nickName"] ||= finance_person["firstName"]
    person["Name"] = "#{person['lastName']}, #{person['nickName']}"
    person["LongTitle"] = finance_person["LibraryTitle"]
    person["StartDate"] = finance_person["StartDate"].strftime('%m/%d/%Y 00:00:00') if finance_person["StartDate"].present?
    person["FireWarden"] = person["FireWarden"] && 1 || 0
    person["BackupFireWarden"] = person["BackupFireWarden"] && 1 || 0
    person.each { |key, value| person[key] = value.to_s }
    person
  end

  def fill_in_with_hr(finance_person:, hr_person:)
    person = finance_person
    person["NetID"] = hr_person["Net ID"]
    person["PUID"] ||= hr_person["EID"]
    person['lastName'] ||= hr_person["Last Name"]
    person['firstName'] ||= hr_person["First Name"]
    person['Email'] ||= "#{hr_person['Net ID']}@princeton.edu"
    person["LibraryTitle"] ||= hr_person["Title"]
    person
  end

  def generate_csv(people)
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
      people.each do |person|
        csv << person.values
      end
    end
  end

  def unquoted_columns(keys)
    unquoted = ["idStaff", "StartDate", "StaffSort", "UnitSort", "DeptSort", "FireWarden", "BackupFireWarden"]
    columns = []
    keys.each_with_index { |key, index| columns << index if unquoted.include?(key) }
    columns
  end
end
