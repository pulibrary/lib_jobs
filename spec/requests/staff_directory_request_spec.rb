# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "StaffDirectories", type: :request do
  let(:adapter) { instance_double(FinanceReportTinyTdsAdapter) }
  let(:finance_report) { instance_double(FinanceReport) }
  let(:hr_report) { instance_double(HrStaffReport) }
  let(:generator) { instance_double(StaffDirectoryGenerator, today: 'abc') }
  let(:new_report) { instance_double(File) }
  let(:old_report) { instance_double(File) }
  let(:staff_difference) { instance_double(StaffDirectoryDifference, ids: ['fouid', 'otherid']) }

  describe "staff-directory" do
    before do
      allow(FinanceReport).to receive(:new).and_return(finance_report)
      allow(HrStaffReport).to receive(:new).and_return(hr_report)
      allow(StaffDirectoryGenerator).to receive(:new).with(finance_report: finance_report, hr_report: hr_report).and_return(generator)
    end
    it "returns the staff directory" do
      get "/staff-directory.csv"
      expect(response.body).to eq('abc')
    end
  end

  describe "removed-staff" do
    before do
      allow(StaffDirectoryDifference).to receive(:new).and_return(staff_difference)
      allow(File).to receive(:new).and_return(new_report, old_report)
    end
    it "returns the staff directory" do
      get "/removed-staff.txt"
      expect(response.body).to eq('fouid,otherid')
    end
  end
end
