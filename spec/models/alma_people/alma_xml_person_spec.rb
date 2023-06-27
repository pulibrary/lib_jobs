# frozen_string_literal: true
require 'rails_helper'

RSpec.describe AlmaPeople::AlmaXmlPerson, type: :model do
  subject(:alma_person) { described_class.new(oit_person_feed:, output_base_dir: '/tmp') }
  let(:xml_builder) {}
  let(:oit_person_feed) { instance_double("AlmaPeople::OitPersonFeed") }

  let(:yesterday) { 1.day.ago.strftime("%Y-%m-%d") }
  let(:today) { Time.zone.now.strftime("%Y-%m-%d") }
  let(:patron_group) { 'P' }

  describe "#run" do
    let(:oit_person) do
      { "PATRON_EXPIRATION_DATE" => "2022-10-31", "PATRON_PURGE_DATE" => "2021-10-31", "ELIGIBLE_INELIGIBLE" => "E", "INSERT_UPDATE_DATETIME" => "2020-12-03T08:21:02.000-05:00",
        "PVSTATCATEGORY" => "EM", "ADDRESS_END_DATE" => "2021-10-31", "PVPATRONGROUP" => patron_group, "DEPTID" => "9999", "DEPT_DESCR" => "PRINCO", "EMPLID" => "999999999",
        "PRF_OR_PRI_FIRST_NAM" => "Sally", "PRF_OR_PRI_LAST_NAME" => "Smith", "PRF_OR_PRI_MIDDLE_NAME" => "Doe", "PU_BARCODE" => "999999999999", "CAMPUS_ID" => "sds99", "CAMP_COUNTRY" => "USA",
        "CAMP_ADDRESS1" => "PRINCO", "CAMP_ADDRESS2" => "99 Princeton Street, Suite 999", "CAMP_ADDRESS3" => nil, "CAMP_ADDRESS4" => nil, "CAMP_CITY" => "Princeton", "CAMP_COUNTY" => nil,
        "CAMP_STATE" => "NJ", "CAMP_POSTAL" => "08544", "CAMP_COUNTRY_DESCR" => "United States", "CAMP_STATE_DESCR" => "New Jersey", "HOME_COUNTRY" => "USA",
        "HOME_ADDRESS1" => "99 WhereILive Street", "HOME_ADDRESS2" => nil, "HOME_ADDRESS3" => nil, "HOME_ADDRESS4" => nil, "HOME_CITY" => "Princeton", "HOME_COUNTY" => "Mercer",
        "HOME_STATE" => "NJ", "HOME_POSTAL" => "08540-4054", "HOME_COUNTRY_DESCR" => "United States", "HOME_STATE_DESCR" => "New Jersey", "HOME_EMAIL" => "sallysmith@gmail.com",
        "HOME_PHONE" => nil, "CAMP_EMAIL" => "sds99@princeton.edu", "PERM_COUNTRY" => "USA", "PERM_ADDRESS1" => "99 WhereILive Circle", "PERM_ADDRESS2" => nil, "PERM_ADDRESS3" => nil,
        "PERM_ADDRESS4" => nil, "PERM_CITY" => "Bradenton", "PERM_COUNTY" => "Manatee", "PERM_STATE" => "FL", "PERM_POSTAL" => "34209", "PERM_COUNTRY_DESCR" => "United States",
        "PERM_STATE_DESCR" => "Florida", "PERM_PHONE" => "123/456-7890", "DORM_COUNTRY" => nil, "DORM_ADDRESS1" => nil, "DORM_ADDRESS2" => nil, "DORM_ADDRESS3" => nil,
        "DORM_ADDRESS4" => nil, "DORM_CITY" => nil, "DORM_COUNTY" => nil, "DORM_STATE" => nil, "DORM_POSTAL" => nil, "DORM_COUNTRY_DESCR" => nil, "DORM_STATE_DESCR" => nil,
        "EMAIL_ADDRESS_END_DATE" => "2022-10-30T20:00:00.000-04:00" }
    end

    let(:work_address) do
      "<address preferred=\"true\" segment_type=\"External\">\n        "\
      "<line1>PRINCO</line1>\n        <line2>99 Princeton Street, Suite 999</line2>\n        <city>Princeton</city>\n        "\
      "<state_province>NJ</state_province>\n        <postal_code/>\n        <country>USA</country>\n        <address_types>\n          "\
      "<address_type desc=\"Work\">work</address_type>\n        </address_types>\n      </address>\n"
    end
    let(:home_address) do
      "<address preferred=\"false\" segment_type=\"External\">\n     "\
      "   <line1>99 WhereILive Street</line1>\n        <city>Princeton</city>\n        "\
      "<state_province>NJ</state_province>\n        <postal_code/>\n        <country>USA</country>\n        <address_types>\n          "\
      "<address_type desc=\"Home\">home</address_type>\n        </address_types>\n      </address>\n"
    end
    let(:addresses) { "<addresses>\n      #{work_address}      #{home_address}    </addresses>\n" }

    let(:alma_xml) do
      "<?xml version=\"1.0\"?>\n<user>\n  <expiry_date>2022-10-31</expiry_date>\n  <purge_date>2021-10-31</purge_date>\n  <status>ACTIVE</status>\n  "\
      "<user_statistics>\n    <user_statistic segment_type=\"External\">\n      <statistic_category desc=\"EM\">EM</statistic_category>\n    </user_statistic>\n  "\
      "</user_statistics>\n  <user_group>#{patron_group}</user_group>\n  <primary_id>999999999</primary_id>\n  <first_name>Sally</first_name>\n  <last_name>Smith</last_name>\n  "\
      "<middle_name>Doe</middle_name>\n  <contact_info>\n    #{addresses}    <emails>\n      "\
      "<email preferred=\"true\" segment_type=\"External\">\n        <email_address>sds99@princeton.edu</email_address>\n        <email_types>\n          "\
      "<email_type desc=\"Work\">work</email_type>\n        </email_types>\n      </email>\n    </emails>\n  </contact_info>\n  "\
      "<user_identifiers>\n    <user_identifier segment_type=\"External\">\n      <value>999999999999</value>\n      "\
      "<id_type desc=\"Barcode\">BARCODE</id_type>\n      <status>ACTIVE</status>\n    </user_identifier>\n    <user_identifier segment_type=\"External\">\n      "\
      "<value>sds99</value>\n      <id_type desc=\"NetID\">NET_ID</id_type>\n      <status>ACTIVE</status>\n    </user_identifier>\n  </user_identifiers>\n"\
      "</user>\n"
    end

    it "generates xml " do
      builder = Nokogiri::XML::Builder.new do |xml|
        alma_person = described_class.new(xml:, person: oit_person)
        alma_person.convert
      end
      expect(builder.to_xml).to eq(alma_xml)
    end

    context "graduate student" do
      let(:patron_group) { 'GRAD' }

      it "generates xml " do
        builder = Nokogiri::XML::Builder.new do |xml|
          alma_person = described_class.new(xml:, person: oit_person)
          alma_person.convert
        end
        expect(builder.to_xml).to eq(alma_xml)
      end
    end

    context "under graduate student" do
      let(:patron_group) { 'UGRD' }
      let(:home_address) do
        "<address preferred=\"true\" segment_type=\"External\">\n     "\
        "   <line1>99 WhereILive Circle</line1>\n        <city>Bradenton</city>\n        "\
        "<state_province>FL</state_province>\n        <postal_code/>\n        <country>USA</country>\n        <address_types>\n          "\
        "<address_type desc=\"Home\">home</address_type>\n        </address_types>\n      </address>\n"
      end
      let(:addresses) { "<addresses>\n      #{home_address}    </addresses>\n" }

      it "generates xml " do
        builder = Nokogiri::XML::Builder.new do |xml|
          alma_person = described_class.new(xml:, person: oit_person)
          alma_person.convert
        end
        expect(builder.to_xml).to eq(alma_xml)
      end
    end

    context "alma person query" do
      let(:alma_person_query) { AlmaPeople::AlmaQueryPersonCSV.new(csv_file: Rails.root.join("spec", "fixtures", 'alma_users_future_exp_no_netid_test.csv')).get_json.first }
      let(:alma_xml) do
        "<?xml version=\"1.0\"?>\n<user>\n  <expiry_date>2014-01-31</expiry_date>\n  <purge_date>2014-01-31</purge_date>\n  <user_group>SENR</user_group>\n  <primary_id>/1/243166d</primary_id>\n"\
        "  <first_name>/1/2D Fleh</first_name>\n  <last_name>middle</last_name>\n  <middle_name>Lehs 11/1/</middle_name>\n"\
        "  <user_identifiers>\n    <user_identifier segment_type=\"External\">\n      <value>999111000</value>\n      <id_type desc=\"Barcode\">BARCODE</id_type>\n"\
        "      <status>ACTIVE</status>\n    </user_identifier>\n    <user_identifier segment_type=\"External\">\n      <value>lehs</value>\n      <id_type desc=\"NetID\">NET_ID</id_type>\n"\
        "      <status>ACTIVE</status>\n    </user_identifier>\n  </user_identifiers>\n</user>\n"
      end

      it "generates xml " do
        builder = Nokogiri::XML::Builder.new do |xml|
          alma_person = described_class.new(xml:, person: alma_person_query)
          alma_person.convert
        end
        expect(builder.to_xml).to eq(alma_xml)
      end
    end

    context 'null expiration date' do
      let(:oit_person) do
        JSON.parse('{
          "PATRON_EXPIRATION_DATE": null,
          "PATRON_PURGE_DATE": null,
          "ELIGIBLE_INELIGIBLE": "E",
          "INSERT_UPDATE_DATETIME": "2021-04-02T08:44:50.000-04:00",
          "PVSTATCATEGORY": null,
          "ADDRESS_END_DATE": null,
          "PVPATRONGROUP": null,
          "DEPTID": null,
          "DEPT_DESCR": null,
          "EMPLID": "999999999",
          "PRF_OR_PRI_FIRST_NAM": "First",
          "PRF_OR_PRI_LAST_NAME": "Last",
          "PRF_OR_PRI_MIDDLE_NAME": "Middle",
          "PU_BARCODE": null,
          "CAMPUS_ID": "patron",
          "CAMP_COUNTRY": "USA",
          "CAMP_ADDRESS1": "Unspecified Dept - Undergrads",
          "CAMP_ADDRESS2": "For Payroll Use Only",
          "CAMP_ADDRESS3": null,
          "CAMP_ADDRESS4": null,
          "CAMP_CITY": "Princeton",
          "CAMP_COUNTY": null,
          "CAMP_STATE": "NJ",
          "CAMP_POSTAL": "08544",
          "CAMP_COUNTRY_DESCR": "United States",
          "CAMP_STATE_DESCR": "New Jersey"
        }')
      end
      it 'is marked invalid' do
        Nokogiri::XML::Builder.new do |xml|
          alma_person = described_class.new(xml:, person: oit_person)
          expect(alma_person.valid?).to eq(false)
          expect(alma_person.errors.messages).to eq({ person: ["doesn't have an expiration date"] })
          expect(alma_person.errors.full_messages).to eq(["Person doesn't have an expiration date"])
        end
      end
    end
  end
end
