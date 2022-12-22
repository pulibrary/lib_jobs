# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "StaffDirectories", type: :request do
  let(:adapter) { instance_double(WebStaff::FinanceReportTinyTdsAdapter) }
  let(:finance_report) { instance_double(WebStaff::FinanceReport) }
  let(:hr_report) { instance_double(WebStaff::HrStaffReport) }
  let(:generator) { instance_double(WebStaff::StaffDirectoryGenerator, today: 'abc') }
  let(:new_report) { instance_double(File) }
  let(:old_report) { instance_double(File) }
  let(:staff_difference) { instance_double(WebStaff::StaffDirectoryDifference, ids: ['fouid', 'otherid']) }

  describe "staff-directory" do
    before do
      allow(WebStaff::FinanceReport).to receive(:new).and_return(finance_report)
      allow(WebStaff::HrStaffReport).to receive(:new).and_return(hr_report)
      allow(WebStaff::StaffDirectoryGenerator).to receive(:new).with(finance_report:, hr_report:).and_return(generator)
    end
    it "returns the staff directory" do
      get "/staff-directory.csv"
      expect(response.body).to eq('abc')
    end
  end

  describe "removed-staff" do
    before do
      allow(WebStaff::StaffDirectoryDifference).to receive(:new).and_return(staff_difference)
      allow(File).to receive(:new).and_return(new_report, old_report)
    end
    it "returns the staff directory" do
      get "/removed-staff.txt"
      expect(response.body).to eq('fouid,otherid')
    end
  end
end
