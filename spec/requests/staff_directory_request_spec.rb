# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "StaffDirectories", type: :request do
  let(:hr_report) { instance_double(WebStaff::HrStaffReport) }
  let(:generator) { instance_double(WebStaff::StaffDirectoryGenerator, today: 'abc') }
  let(:new_report) { instance_double(File) }
  let(:old_report) { instance_double(File) }
  let(:staff_difference) { instance_double(WebStaff::StaffDirectoryDifference, ids: ['fouid', 'otherid']) }

  describe "staff-directory" do
    before do
      allow(WebStaff::HrStaffReport).to receive(:new).and_return(hr_report)
      allow(WebStaff::StaffDirectoryGenerator).to receive(:new).with(hr_report:).and_return(generator)
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

  describe "staff report with ip filtering" do
    it "allows access from localhost" do
      get "/pul-staff-report", env: { "REMOTE_ADDR" => "127.0.0.1" }
      expect(response).to have_http_status(:success)
    end
    it "denies access from other ips" do
      expect {
        get "/pul-staff-report", env: { "REMOTE_ADDR" => "104.16.90.41" }
      }.to raise_error(ActionController::RoutingError)
    end
  end
end
