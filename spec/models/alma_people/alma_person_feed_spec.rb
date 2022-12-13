# frozen_string_literal: true
require 'rails_helper'

RSpec.describe AlmaPeople::AlmaPersonFeed, type: :model do
  subject(:alma_person_feed) { described_class.new(oit_person_feed: oit_person_feed, output_base_dir: '/tmp') }
  let(:oit_person_feed) { instance_double("AlmaPeople::OitPersonFeed") }

  let(:yesterday) { 1.day.ago.strftime("%Y-%m-%d") }
  let(:today) { Time.zone.now.strftime("%Y-%m-%d") }

  let(:sftp) { instance_double("Net::SFTP::Session") }

  describe "#run" do
    let(:oit_people) do
      [{ "PATRON_EXPIRATION_DATE" => "2022-10-31", "PATRON_PURGE_DATE" => "2021-10-31", "ELIGIBLE_INELIGIBLE" => "E", "INSERT_UPDATE_DATETIME" => "2020-12-03T08:21:02.000-05:00",
         "PVSTATCATEGORY" => "EM", "ADDRESS_END_DATE" => "2021-10-31", "PVPATRONGROUP" => "P", "DEPTID" => "9999", "DEPT_DESCR" => "PRINCO", "EMPLID" => "999999999",
         "PRF_OR_PRI_FIRST_NAM" => "Sally", "PRF_OR_PRI_LAST_NAME" => "Smith", "PRF_OR_PRI_MIDDLE_NAME" => "Doe", "PU_BARCODE" => "999999999999", "CAMPUS_ID" => "sds99", "CAMP_COUNTRY" => "USA",
         "CAMP_ADDRESS1" => "PRINCO", "CAMP_ADDRESS2" => "99 Princeton Street, Suite 999", "CAMP_ADDRESS3" => nil, "CAMP_ADDRESS4" => nil, "CAMP_CITY" => "Princeton", "CAMP_COUNTY" => nil,
         "CAMP_STATE" => "NJ", "CAMP_POSTAL" => "08544", "CAMP_COUNTRY_DESCR" => "United States", "CAMP_STATE_DESCR" => "New Jersey", "HOME_COUNTRY" => "USA",
         "HOME_ADDRESS1" => "99 WhereILive Street", "HOME_ADDRESS2" => nil, "HOME_ADDRESS3" => nil, "HOME_ADDRESS4" => nil, "HOME_CITY" => "Princeton", "HOME_COUNTY" => "Mercer",
         "HOME_STATE" => "NJ", "HOME_POSTAL" => "08540-4054", "HOME_COUNTRY_DESCR" => "United States", "HOME_STATE_DESCR" => "New Jersey", "HOME_EMAIL" => "sallysmith@gmail.com",
         "HOME_PHONE" => nil, "CAMP_EMAIL" => "sds99@princeton.edu", "PERM_COUNTRY" => "USA", "PERM_ADDRESS1" => "99 WhereILive Circle", "PERM_ADDRESS2" => nil, "PERM_ADDRESS3" => nil,
         "PERM_ADDRESS4" => nil, "PERM_CITY" => "Bradenton", "PERM_COUNTY" => "Manatee", "PERM_STATE" => "FL", "PERM_POSTAL" => "34209", "PERM_COUNTRY_DESCR" => "United States",
         "PERM_STATE_DESCR" => "Florida", "PERM_PHONE" => "123/456-7890", "DORM_COUNTRY" => nil, "DORM_ADDRESS1" => nil, "DORM_ADDRESS2" => nil, "DORM_ADDRESS3" => nil,
         "DORM_ADDRESS4" => nil, "DORM_CITY" => nil, "DORM_COUNTY" => nil, "DORM_STATE" => nil, "DORM_POSTAL" => nil, "DORM_COUNTRY_DESCR" => nil, "DORM_STATE_DESCR" => nil,
         "EMAIL_ADDRESS_END_DATE" => "2022-10-30T20:00:00.000-04:00" }]
    end

    before do
      allow(oit_person_feed).to receive(:get_json).with(begin_date: yesterday, end_date: today, enabled_flag: "E").and_return(oit_people)
      allow(Net::SFTP).to receive(:start).and_yield(sftp)
      allow(sftp).to receive(:upload!)
    end

    it "generates an xml file" do
      expect(alma_person_feed.run).to be_truthy
      expect(oit_person_feed).to have_received(:get_json)
      expect(sftp).to have_received(:upload!).with("/tmp/alma_people_#{yesterday}_#{today}_E.xml.zip", "/alma/people/alma_people_#{yesterday}_#{today}_E.xml.zip")
      data_set = DataSet.last
      expect(data_set.category).to eq("AlmaPersonFeed")
      expect(data_set.report_time).to eq(Time.zone.now.midnight)
      expect(data_set.data).to eq("people_updated: 1, file: alma_people_#{yesterday}_#{today}_E.xml")
      data = File.read("/tmp/alma_people_#{yesterday}_#{today}_E.xml")
      expect(validate_xml(data)).to be_truthy
    end

    context "no people" do
      let(:oit_people) { [] }

      it "generates no xml file" do
        expect(alma_person_feed.run).to be_truthy
        expect(oit_person_feed).to have_received(:get_json)
        expect(sftp).not_to have_received(:upload!)
        data_set = DataSet.last
        expect(data_set.category).to eq("AlmaPersonFeed")
        expect(data_set.report_time).to eq(Time.zone.now.midnight)
        expect(data_set.data).to eq("people_updated: 0, file: ")
      end
    end

    context "blank dates" do
      subject(:alma_person_feed) { described_class.new(oit_person_feed: oit_person_feed, output_base_dir: '/tmp', begin_date: nil, end_date: nil, enabled_flag: nil) }

      before do
        allow(oit_person_feed).to receive(:get_json).with(begin_date: nil, end_date: nil, enabled_flag: nil).and_return(oit_people)
      end

      it "generates an xml file" do
        expect(alma_person_feed.run).to be_truthy
        expect(oit_person_feed).to have_received(:get_json)
        expect(sftp).to have_received(:upload!).with("/tmp/alma_people_#{yesterday}.xml.zip", "/alma/people/alma_people_#{yesterday}.xml.zip")
        data_set = DataSet.last
        expect(data_set.category).to eq("AlmaPersonFeed")
        expect(data_set.report_time).to eq(Time.zone.now.midnight)
        expect(data_set.data).to eq("people_updated: 1, file: alma_people_#{yesterday}.xml")
        data = File.read("/tmp/alma_people_#{yesterday}.xml")
        expect(validate_xml(data)).to be_truthy
      end
    end

    context 'invalid users' do
      before do
        allow_any_instance_of(AlmaPeople::AlmaXmlPerson).to receive(:valid?).and_return(false) # rubocop:disable RSpec/AnyInstance
        allow(ENV).to receive(:fetch).and_return('person_1@princeton.edu,person_2@princeton.edu,person_3@princeton.edu')
      end
      it 'sends an email' do
        expect { alma_person_feed.run }.to change { ActionMailer::Base.deliveries.count }.by(1)
      end
    end
  end

  def validate_xml(data)
    xsd = Nokogiri::XML::Schema(File.open(Rails.root.join("spec", "fixtures", 'rest_users.xsd')))
    doc = Nokogiri::XML(data)
    xsd.validate(doc).each do |error|
      puts error.message
    end
    xsd.valid?(doc)
  end
end
