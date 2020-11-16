# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HrStaffReport, type: :model do
  let(:heading_line) { "Department Number\tDepartment Name\tBsns Unit\tEID\tNet ID\tLast Name\tFirst Name\tMiddle Name\tPaid\tReg/Temp - Description\tPos #\tTitle\tAbsence Manager\tManager Net ID" }
  let(:user_line) { "90009\tTest Department\tPUHRS\t99999999\ttesti\tTest\tI\tam\tBiw\tR=BenElig\t000000000\tLibrary Office Assistant II\tManager, I Am.\timanager" }
  let(:manager_line) { "90009\tTest Department\tPUHRS\t99999991\timanager\tManager\tI\tam\tBiw\tR=BenElig\t000000000\tManager II\tLibrary, Dean of\tajarvis" }
  let(:dean_line) { "41000\tTest Department\tPUHRS\t99999991\tajarvis\tJarvis\tAnn\t\tBiw\tR=BenElig\t000000000\tManager II\tLibrary, Dean of\tomanager" }

  let(:result_hash) do
    { "Department Number" => "90009", "Absence Manager" => "Manager, I Am.", "Bsns Unit" => "PUHRS", "Department Name" => "Test Department", "EID" => "99999999", "First Name" => "I",
      "Last Name" => "Test", "Manager Net ID" => "imanager", "Middle Name" => "am", "Net ID" => "testi", "Paid" => "Biw", "Pos #" => "000000000", "Reg/Temp - Description" => "R=BenElig",
      "Title" => "Library Office Assistant II" }
  end

  let(:report) { described_class.new(hr_data: hr_data) }
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
end
