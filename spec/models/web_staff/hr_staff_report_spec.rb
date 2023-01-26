# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WebStaff::HrStaffReport, type: :model do
  # rubocop:disable Layout/LineLength
  let(:heading_line) { "Department Number\tDepartment Name\tDepartment Long Name\tBsns Unit\tEID\tFirst Name\tMiddle Name\tLast Name\tNick Name\tNet ID\tPaid\tReg/Temp - Description\tPos #\tTitle\tRegister Title\tAbsence Manager\tManager Net ID\tPosition Number\tCampus Address - Address 1\tCampus Address - Address 2\tCampus Address - Address 3\tCampus Address - City\tCampus Address - State\tCampus Address - Postal Code\tCampus Address - Country\tPhone\tE-Mail" }
  let(:user_line) { "90009\tTest Department\tTest Department Long\tPUHRS\t99999999\tI\tam\tTest\tTesty\ttesti\tBiw\tR=BenElig\t000000000\tLibrary Office Assistant II\t\tManager, I Am.\timanager\t000000001\tFirestone Library\tLibrary Information Technology\t \tPrinceton\tNJ\t08544\tUSA\t732/111-2222\ttesti@Princeton.EDU" }
  let(:manager_line) { "90009\tTest Department\tTest Department Long\tPUHRS\t99999991\tI\tam\tManager\t\timanager\tBiw\tR=BenElig\t000000001\tManager II\tLibrary, Dean of\tManager for the Library Dean\tajarvis\t000000002\tFirestone Library\tLibrary Information Technology\t \tPrinceton\tNJ\t08544\tUSA\t732/111-2233\ttesti@Princeton.EDU" }
  let(:dean_line) { "41000\tTest Department\tTest Department Long\tPUHRS\t99999991\tAnn\t\tJarvis\t\tajarvis\tBiw\tR=BenElig\t000000002\tLibrary Dean\tThe Dean of the Priceton Library\tLibrary, Dean of\tomanager\t000000007\tFirestone Library\tFinance and Administration\t \tPrinceton\tNJ\t08544\tUSA\t732/111-2244\ttesti@Princeton.EDU" }
  # rubocop:enable Layout/LineLength

  let(:result_hash) do
    { "Department Number" => "90009", "Absence Manager" => "Manager, I Am.", "Bsns Unit" => "PUHRS", "Department Name" => "Test Department", "EID" => "99999999", "First Name" => "I",
      "Last Name" => "Test", "Manager Net ID" => "imanager", "Middle Name" => "am", "Net ID" => "testi", "Paid" => "Biw", "Pos #" => "000000000", "Reg/Temp - Description" => "R=BenElig",
      "Title" => "Library Office Assistant II", "E-Mail" => "testi@Princeton.EDU", "Phone" => "732/111-2222", "Position Number" => "000000001", # this is the mamanger's position number
      "Campus Address - Address 1" => "Firestone Library", "Campus Address - Address 2" => "Library Information Technology", "Campus Address - Address 3" => " ",
      "Campus Address - City" => "Princeton", "Campus Address - Country" => "USA", "Campus Address - Postal Code" => "08544", "Campus Address - State" => "NJ",
      "Department Long Name" => "Test Department Long", "Nick Name" => "Testy", "Register Title" => nil }
  end

  let(:report) { described_class.new(hr_data:) }
  let(:hr_data) { "#{heading_line}\n#{user_line}" }
  it 'reads a list from the csv file' do
    expect(report.count).to eq(1)
    expect(report.first.to_h).to eq(result_hash)
  end

  it "responds to each" do
    report.each do |person|
      expect(person.to_h).to eq(result_hash)
    end
  end

  context "when no data is passed" do
    let(:report) { described_class.new }
    it "uses the default location" do
      allow(File).to receive(:new).with('hr_staff_report_location', encoding: "UTF-16").and_return(hr_data)
      expect(report.count).to eq(1)
      expect(report.first.to_h).to eq(result_hash)
    end
  end
  context "multiple lines" do
    let(:hr_data) { "#{heading_line}\n#{dean_line}\n#{manager_line}\n#{user_line}" }

    it 'reads a list from the csv file' do
      expect(report.count).to eq(3)
      expect(report.last.to_h).to eq(result_hash)
    end
  end

  describe '#people' do
    context "incorrect CSV headers" do
      let(:heading_line) { "Campus Address - Country\tPhone\tE-Mail" }
      it 'throws an error' do
        expect { report.people }.to raise_error(CSVValidator::InvalidHeadersError)
      end
    end
  end
end
