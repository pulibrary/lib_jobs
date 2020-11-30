# frozen_string_literal: true
require 'rails_helper'

RSpec.describe StaffDirectoryGenerator, type: :model do
  let(:heading_line) { "Department Number\tDepartment Name\tBsns Unit\tEID\tNet ID\tLast Name\tFirst Name\tMiddle Name\tPaid\tReg/Temp - Description\tPos #\tTitle\tAbsence Manager\tManager Net ID" }
  let(:user1_line) { "90009\tTest Department\tPUHRS\t999999999\ttesti\tTest\tI\tam\tBiw\tR=BenElig\t000000000\tLibrary Office Assistant I\tManager, I Am.\timanager" }
  let(:user2_line) { "90009\tTest Department\tPUHRS\t999999998\ttestii\tTest\tII\tam\tBiw\tR=BenElig\t000000000\tLibrary Office Assistant II\tManager, I Am.\timanager" }
  let(:user3_line) { "90009\tTest Department\tPUHRS\t999999997\ttestiii\tTest\tIII\tam\tBiw\tR=BenElig\t000000000\tLibrary Office Assistant III\tManager, I Am.\timanager" }
  let(:hr_data) { "#{heading_line}\n#{user1_line}\n#{user2_line}\n#{user3_line}" }
  let(:hr_report) { HrStaffReport.new(hr_data: hr_data) }

  let(:finance_report1) do
    { 'idStaff' => 111, 'PUID' => '999999999', 'NetID' => 'testi', 'Phone' => '111-222-333', "Name" => 'Am, Test', 'lastName' => 'Am', 'firstName' => 'Test', 'middleName' => 'I',
      'nickName' => 'Tester', 'Title' => 'The Great Assistant', 'LibraryTitle' => 'The Great Library Assistant', 'LongTitle' => 'The Great Assistant Is Longer', 'Email' => 'testi@princeton.edu',
      'Section' => 'section from DB', 'Division' => 'Division from DB', 'Department' => 'Lib-Research Coll & Presr', 'StartDate' => Time.zone.parse('2019-04-15 00:00:00 -0400'),
      'StaffSort' => 10_000, 'UnitSort' => 1_000, 'DeptSort' => 10, 'Unit' => nil, 'DivSect' => 'Division from DB  section from DB', 'FireWarden' => false, 'BackupFireWarden' => false,
      'FireWardenNotes' => nil, 'Office' => 'B-18', 'Building' => 'Firestone' }
  end
  let(:finance_report2) do
    new_result = finance_report1.dup
    new_result['NetID'] = 'testii'
    new_result['Email'] = 'testii@princeton.edu'
    new_result['middleName'] = 'II'
    new_result['PUID'] = '999999998'
    new_result
  end
  let(:finance_report3) do
    new_result = finance_report1.dup
    new_result['NetID'] = 'testiii'
    new_result['Email'] = 'testiii@princeton.edu'
    new_result['middleName'] = 'III'
    new_result['PUID'] = '999999997'
    new_result
  end
  let(:finance_report) { instance_double(FinanceReport) }

  # these are actual lines in the file, so lets ignore rubocop an keep them together
  # rubocop:disable Layout/LineLength
  let(:report_header)  { '"idStaff","PUID","NetID","Phone","Name","lastName","firstName","middleName","nickName","Title","LibraryTitle","LongTitle","Email","Section","Division","Department","StartDate","StaffSort","UnitSort","DeptSort","Unit","DivSect","FireWarden","BackupFireWarden","FireWardenNotes","Office","Building"' }

  let(:report_line1) { '111,"999999999","testi","111-222-333","Am, Tester","Am","Test","I","Tester","The Great Assistant","The Great Library Assistant","The Great Library Assistant","testi@princeton.edu","section from DB","Division from DB","Lib-Research Coll & Presr",04/15/2019 00:00:00,10000,1000,10,,"Division from DB  section from DB",0,0,,"B-18","Firestone"' }
  let(:report_line2) { '111,"999999998","testii","111-222-333","Am, Tester","Am","Test","II","Tester","The Great Assistant","The Great Library Assistant","The Great Library Assistant","testii@princeton.edu","section from DB","Division from DB","Lib-Research Coll & Presr",04/15/2019 00:00:00,10000,1000,10,,"Division from DB  section from DB",0,0,,"B-18","Firestone"' }
  let(:report_line3) { '111,"999999997","testiii","111-222-333","Am, Tester","Am","Test","III","Tester","The Great Assistant","The Great Library Assistant","The Great Library Assistant","testiii@princeton.edu","section from DB","Division from DB","Lib-Research Coll & Presr",04/15/2019 00:00:00,10000,1000,10,,"Division from DB  section from DB",0,0,,"B-18","Firestone"' }
  let(:report_line4) { '111,"999999997","testiv","111-222-333","Am, Tester","Am","Test","IV","Tester","The Great Assistant","The Great Library Assistant","The Great Library Assistant","testiv@princeton.edu","section from DB","Division from DB","Lib-Research Coll & Presr",04/15/2019 00:00:00,10000,1000,10,,"Division from DB  section from DB",0,0,,"B-18","Firestone"' }
  # rubocop:enable Layout/LineLength

  let(:hr_list) do
    "Department Number	Department Name	Bsns Unit	EID	Net ID	Last Name	First Name	Middle Name	Paid	Reg/Temp - Description	Pos #	Title	Absence Manager	Manager Net ID	Position Number\n" \
    "10001	Lib-Research Coll & Presr Cons	PUHRS	999999999	foid	Smith	Jane	Biw	R=BenElig	00006823	The Great Assistant	Myers,Cory Andrew	corym	00008179\n"
  end
  let(:generator) { described_class.new(finance_report: finance_report, hr_report: hr_report) }

  describe "#report" do
    # rubocop:disable RSpec/MessageSpies
    before do
      expect(finance_report).to receive(:report).with(employee_id: '999999999').and_return(finance_report1)
      expect(finance_report).to receive(:report).with(employee_id: '999999998').and_return(finance_report2)
      expect(finance_report).to receive(:report).with(employee_id: '999999997').and_return("idStaff" => nil, "PUID" => nil, "NetID" => nil, "Phone" => nil, "Name" => nil, "lastName" => nil,
                                                                                           "firstName" => nil, "middleName" => nil, "nickName" => nil, "Title" => nil, "LibraryTitle" => nil,
                                                                                           "LongTitle" => nil, "Email" => nil, "Section" => nil, "Division" => nil, "Department" => nil,
                                                                                           "StartDate" => nil, "StaffSort" => nil, "UnitSort" => nil,
                                                                                           "DeptSort" => nil, "Unit" => nil, "DivSect" => nil, "FireWarden" => false, "BackupFireWarden" => false,
                                                                                           "FireWardenNotes" => nil, "Office" => nil, "Building" => nil)
    end

    let(:report_line3) { ',"999999997","testiii",,"Test, III","Test","III",,"III",,"Library Office Assistant III","Library Office Assistant III","testiii@princeton.edu",,,,,,,,,,0,0,,,' }

    # rubocop:enable RSpec/MessageSpies
    it "generates the staff list csv" do
      expect(generator.report).to eq("#{report_header}\n#{report_line1}\n#{report_line2}\n#{report_line3}\n")
    end
  end

  describe "#today" do
    let(:yesterday) { Date.yesterday.strftime("%Y%m%d") }
    let(:report_filename) { Rails.root.join('tmp').join('staff-directory-test.csv') }
    let(:yesterday_filename) { "#{report_filename}_#{yesterday}" }

    before do
      File.open(report_filename, "w") do |file|
        file.write("#{report_header}\n#{report_line1}\n#{report_line2}\n#{report_line3}\n#{report_line4}\n")
      end
      allow(finance_report).to receive(:report).with(employee_id: '999999999').and_return(finance_report1)
      allow(finance_report).to receive(:report).with(employee_id: '999999998').and_return(finance_report2)
      allow(finance_report).to receive(:report).with(employee_id: '999999997').and_return(finance_report3)
    end
    after do
      File.delete(report_filename) if File.exist?(report_filename)
      File.delete(yesterday_filename) if File.exist?(yesterday_filename)
    end
    it "generates the report" do
      expect(generator.today).to eq("#{report_header}\n#{report_line1}\n#{report_line2}\n#{report_line3}\n")
    end

    context "already exists on disk" do
      before do
        File.open(yesterday_filename, "w") do |file|
          file.write("#{report_header}\n#{report_line1}\n#{report_line2}\n")
        end
      end
      it "serves up the report from disk" do
        expect(generator.today).to eq("#{report_header}\n#{report_line1}\n#{report_line2}\n#{report_line3}\n#{report_line4}\n")
      end
    end
  end
end
