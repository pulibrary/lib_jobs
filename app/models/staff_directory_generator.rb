# frozen_string_literal: true

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
      finance_data = finance_report.report(employee_id: person["EID"])
      people << create_person_hash(finance_person: finance_data, hr_person: person)
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

  def create_person_hash(finance_person:, hr_person:)
    person = fill_in_with_hr(finance_person: finance_person, hr_person: hr_person)
    person = fill_in_with_ldap(person)
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

  def fill_in_with_ldap(person)
    ldap_data = Ldap.find_by_netid(person["NetID"])
    person['Email'] = ldap_data[:email]
    if ldap_data[:address]
      address = ldap_data[:address].split(' ')
      person['Office'] = address.shift
      person['Building'] = address.join(' ')
    end
    person['Phone'] = ldap_data[:telephone]
    person['LibraryTitle'] ||= ldap_data[:title]
    person
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
