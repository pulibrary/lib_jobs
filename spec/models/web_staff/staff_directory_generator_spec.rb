# frozen_string_literal: true
require 'rails_helper'

RSpec.describe WebStaff::StaffDirectoryGenerator, type: :model do
  # rubocop:disable Layout/LineLength
  let(:heading_line) { "Department Number\tDepartment Name\tDepartment Long Name\tBsns Unit\tEID\tFirst Name\tMiddle Name\tLast Name\tNick Name\tNet ID\tPaid\tReg/Temp - Description\tPos #\tTitle\tRegister Title\tAbsence Manager\tManager Net ID\tPosition Number\tOL1 Address - Address 1\tOffice Location - Description\tCampus Address - Address 3\tCampus Address - City\tCampus Address - State\tCampus Address - Postal Code\tCampus Address - Country\tOL1 Phone - Phone Number\tE-Mail" }
  let(:user1_line) { "90009\tTest Department\tTest Department Long\tPUHRS\t999999999\tI\tam\tTest\tTester\ttesti\tBiw\tR=BenElig\t000000000\tLibrary Office Assistant I\tLibrary Office Assistant One\tManager, I Am.\timanager\t000000001\tFirestone Library\tLibrary Information Technology\t \tPrinceton\tNJ\t08544\tUSA\t609/258-2222\ttesti@Princeton.EDU" }
  let(:user2_line) { "90009\tTest Department\tTest Department Long\tPUHRS\t999999998\tII\tam\tTest\tTesti\ttestii\tBiw\tR=BenElig\t000000000\tLibrary Office Assistant II\tLibrary Office Assistant Two\tManager, I Am.\timanager\t000000001\tFirestone Library\tLibrary Information Technology\t \tPrinceton\tNJ\t08544\tUSA\t609/258-2223\ttestii@Princeton.EDU" }
  let(:user3_line) { "90009\tTest Department\tTest Department Long\tPUHRS\t999999997\tIII\tam\tTest\tTestii\ttestiii\tBiw\tR=BenElig\t000000000\tLibrary Office Assistant III\tLibrary Office Assistant Three\tManager, I Am.\timanager\t000000001\tFirestone Library\tLibrary Information Technology\t \tPrinceton\tNJ\t08544\tUSA\t609/258-2224\ttestiii@Princeton.EDU" }
  # rubocop:enable Layout/LineLength

  let(:hr_data) { "#{heading_line}\n#{user1_line}\n#{user2_line}\n#{user3_line}" }
  let(:hr_report) { WebStaff::HrStaffReport.new(hr_data:) }

  # these are actual lines in the file, so lets ignore rubocop an keep them together
  # rubocop:disable Layout/LineLength
  let(:report_header)  { '"PUID","NetID","Phone","Name","lastName","firstName","middleName","nickName","Title","LibraryTitle","LongTitle","Email","Section","Division","Department","StartDate","StaffSort","UnitSort","DeptSort","Unit","DivSect","FireWarden","BackupFireWarden","FireWardenNotes","Office","Building"' }

  let(:report_line1) { '"999999999","testi","(609) 258-2222","Test, Tester","Test","I","am","Tester","Library Office Assistant I","Library Office Assistant One","Library Office Assistant One","testi@princeton.edu",,,"Test Department Long",,,,,,,,0,,"B-1H-1","Firestone"' }
  let(:report_line2) { '"999999998","testii","(609) 258-2223","Test, Testi","Test","II","am","Testi","Library Office Assistant II","Library Office Assistant Two","Library Office Assistant Two","testii@princeton.edu",,,"Test Department Long",,,,,,,,0,,"223A","693 Alexander Road"' }
  let(:report_line3) { '"999999997","testiii","(609) 258-2224","Test, Testii","Test","III","am","Testii","Library Office Assistant III","Library Office Assistant Three","Library Office Assistant Three","testiii@princeton.edu",,,"Test Department Long",,,,,,,,0,,"Library Information Technology","Firestone Library"' }
  let(:report_line4) { '"999999996","testiv","(609) 258-2225","Test, Testiii","Test","III","am","Testiii","Library Office Assistant IV","Library Office Assistant Four","Library Office Assistant Four","testiv@princeton.edu",,,"Test Department Long",,,,,,,,0,,"Library Information Technology","Firestone Library"' }
  # rubocop:enable Layout/LineLength

  let(:hr_list) do
    "Department Number	Department Name	Bsns Unit	EID	Net ID	Last Name	First Name	Middle Name	Paid	Reg/Temp - Description	Pos #	Title	Absence Manager	Manager Net ID	Position Number\n" \
    "10001	Test Department Long Cons	PUHRS	999999999	foid	Smith	Jane	Biw	R=BenElig	00006823	The Great Assistant	Myers,Cory Andrew	corym	00008179\n"
  end
  let(:generator) { described_class.new(hr_report:) }

  before do
    allow(WebStaff::Ldap).to receive(:find_by_netid).with('testi').and_return({ email: 'testi@princeton.edu', address: 'B-1H-1 Firestone', telephone: '111-222-3333',
                                                                                title: "The Great LDAP Assistant" })
    allow(WebStaff::Ldap).to receive(:find_by_netid).with('testii').and_return({ email: 'testii@princeton.edu', address: '223A 693 Alexander Road',
                                                                                 telephone: '222-333-4444', title: "The Great LDAP Assistant" })
    allow(WebStaff::Ldap).to receive(:find_by_netid).with('testiii').and_return({ email: 'testiii@princeton.edu', telephone: '333-444-5555', title: "The Great LDAP Assistant" })
  end

  after do
    DataSet.all.each { |data_set| File.delete(data_set.data_file) }
  end

  describe "#run" do
    it "generates the staff list csv" do
      expect(generator.run).to be_truthy
      data_set = DataSet.last
      expect(data_set.category).to eq("StaffDirectory")
      expect(data_set.report_time).to eq(Time.zone.now.midnight)
      report_data = File.open(data_set.data_file).read
      expect(report_data).to eq("#{report_header}\n#{report_line1}\n#{report_line2}\n#{report_line3}\n")
    end

    context 'when phone numbers are empty or invalid' do
      # rubocop:disable Layout/LineLength
      let(:user1_line) { "90009\tTest Department\tTest Department Long\tPUHRS\t999999999\tI\tam\tTest\tTester\ttesti\tBiw\tR=BenElig\t000000000\tLibrary Office Assistant I\tLibrary Office Assistant One\tManager, I Am.\timanager\t000000001\tFirestone Library\tLibrary Information Technology\t \tPrinceton\tNJ\t08544\tUSA\t123/555-2222\ttesti@Princeton.EDU" }
      let(:user2_line) { "90009\tTest Department\tTest Department Long\tPUHRS\t999999998\tII\tam\tTest\tTesti\ttestii\tBiw\tR=BenElig\t000000000\tLibrary Office Assistant II\tLibrary Office Assistant Two\tManager, I Am.\timanager\t000000001\tFirestone Library\tLibrary Information Technology\t \tPrinceton\tNJ\t08544\tUSA\t \ttestii@Princeton.EDU" }
      let(:report_line1) { '"999999999","testi",,"Test, Tester","Test","I","am","Tester","Library Office Assistant I","Library Office Assistant One","Library Office Assistant One","testi@princeton.edu",,,"Test Department Long",,,,,,,,0,,"B-1H-1","Firestone"' }
      let(:report_line2) { '"999999998","testii",,"Test, Testi","Test","II","am","Testi","Library Office Assistant II","Library Office Assistant Two","Library Office Assistant Two","testii@princeton.edu",,,"Test Department Long",,,,,,,,0,,"223A","693 Alexander Road"' }
      # rubocop:enable Layout/LineLength

      it 'leaves the column empty for that staff member' do
        generator.run
        data_set = DataSet.last
        report_data = File.open(data_set.data_file).read
        expect(report_data).to eq("#{report_header}\n#{report_line1}\n#{report_line2}\n#{report_line3}\n")
      end
    end
  end

  describe "#today" do
    let(:report_filename) { described_class.report_filename }

    it "generates the report" do
      expect { expect(generator.today).to eq("#{report_header}\n#{report_line1}\n#{report_line2}\n#{report_line3}\n") }.to change(DataSet, :count).by(1)
    end

    context "already exists on disk" do
      before do
        File.open(report_filename, "w") do |file|
          file.write("#{report_header}\n#{report_line1}\n#{report_line2}\n#{report_line3}\n#{report_line4}\n")
        end
        DataSet.create(category: "StaffDirectory", report_time: Time.zone.now.midnight, data_file: report_filename)
      end
      it "serves up the report from disk" do
        expect(generator.today).to eq("#{report_header}\n#{report_line1}\n#{report_line2}\n#{report_line3}\n#{report_line4}\n")
        expect(WebStaff::Ldap).not_to have_received(:find_by_netid).with('testi')
      end
    end
  end
end
