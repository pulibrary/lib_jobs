# frozen_string_literal: true
module WebStaff
  class StaffMember
    attr_reader :hr_person, :hash

    def initialize(hr_person)
      @hr_person = hr_person
      @hash = {}
      convert
    end

    private

    def convert
      fill_in_with_hr
      fill_in_with_ldap
      hash["LongTitle"] = hash["LibraryTitle"]
      insert_empty_fields(keys: ["StartDate", "FireWarden"])
      hash["BackupFireWarden"] = hash["BackupFireWarden"] && 1 || 0
      hash.each { |key, value| hash[key] = value.to_s }
    end

    def fill_in_with_hr
      hash["PUID"] = hr_person["EID"]
      hash["NetID"] = hr_person["Net ID"]
      hash['Phone'] = hr_person["Phone"]
      convert_name
      convert_title
      hash['Email'] = hr_person['E-Mail'].downcase
      insert_empty_fields(keys: ["Section", "Division"])
      hash["Department"] = hr_person["Department Long Name"]
      insert_empty_fields
      hash['Office'] = hr_person['Campus Address - Address 2']
      hash['Building'] = hr_person['Campus Address - Address 1']
    end

    def convert_title
      hash['Title'] = hr_person["Title"]
      hash["LibraryTitle"] = if hr_person["Register Title"].strip.blank?
                               hr_person["Title"]
                             else
                               hr_person["Register Title"]
                             end
      hash['LongTitle'] = hr_person["Register Title"]
    end

    def convert_name
      hash['Phone'] = hr_person["Phone"]
      hash["Name"] = "#{hr_person['Last Name']}, #{hr_person['Nick Name'] || hr_person['First Name']}"
      hash['lastName'] = hr_person["Last Name"]
      hash['firstName'] = hr_person["First Name"]
      hash['middleName'] = hr_person["Middle Name"]
      hash["nickName"] = hr_person["Nick Name"] || hr_person["First Name"]
    end

    def insert_empty_fields(keys: ["StartDate", "StaffSort", "UnitSort", "DeptSort", "Unit", "DivSect", "FireWarden", "BackupFireWarden", "FireWardenNotes"])
      keys.each do |key|
        hash[key] = nil
      end
    end

    def fill_in_with_ldap
      ldap_data = WebStaff::Ldap.find_by_netid(hash["NetID"])
      return unless ldap_data[:address]
      address = ldap_data[:address].split(' ')
      hash['Office'] = address.shift
      hash['Building'] = address.join(' ')
    end
  end
end
