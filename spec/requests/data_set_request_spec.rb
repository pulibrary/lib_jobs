# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "DataSets", type: :request do
  let(:previous_time) { 3.days.ago.midnight }
  let(:previous_time_string) { previous_time.midnight }
  let(:today) { DateTime.now.midnight }
  let(:today_string) { today.strftime('%Y-%m-%d') }
  let(:today_end_of_hour) { today.end_of_hour }
  let(:today_time_string) { today.strftime('%Y-%m-%d %H:%M:%S %Z') }

  describe "index" do
    let(:data_set1) { create(:data_set, report_time: today, data: "abc123,def456", data_file: nil, category: "StaffDirectoryRemoved") }
    let(:data_set2) { create(:data_set, report_time: today_end_of_hour, data: "abc123,def456", data_file: nil, category: "Other") }
    let(:data_set3) { create(:data_set, report_time: previous_time, data: "zzz999,yyy888", data_file: nil, category: "StaffDirectoryAdded") }

    before do
      data_set3
      data_set2
      data_set1
    end

    it "returns all the datasets" do
      get "/"
      expect(response.body).to include(previous_time.to_s).once
      expect(response.body).to include(today_string).twice
      expect(response.body).to include('StaffDirectoryRemoved').once
      expect(response.body).to include('StaffDirectoryAdded').once
      expect(response.body).to include('Other').once
    end

    it "can be filtered by category" do
      get "/?category=StaffDirectoryAdded"
      expect(response.body).to include(previous_time.to_s).once
      expect(response.body).not_to include('StaffDirectoryRemoved')
      expect(response.body).to include('StaffDirectoryAdded').once
    end

    it "can be filtered by date" do
      get "/?report_date=#{today_string}"
      expect(response.body).to include(today_string).twice
      expect(response.body).to include('StaffDirectoryRemoved')
      expect(response.body).not_to include('StaffDirectoryAdded').once
      expect(response.body).to include('Other').once
    end

    it "can be filtered by an exact time" do
      get "/?report_time=#{today_time_string}"
      expect(response.body).to include(today_string).once
      expect(response.body).to include('StaffDirectoryRemoved')
      expect(response.body).not_to include('StaffDirectoryAdded').once
    end
  end

  describe "latest" do
    context "when the client passes an invalid JSON Web Token" do
      let(:user) do
        User.create(email: 'user@localhost')
      end

      let(:headers) do
        {
          "Accept" => "application/json",
          "Authorization" => "Bearer invalid"
        }
      end

      let(:params) do
        {
          user: { id: user.id }
        }
      end

      before do
        user
      end

      after do
        user.destroy
      end

      it "denies the request" do
        get "/data_sets/latest/other", headers: headers, params: params

        expect(response.forbidden?).to be true
      end
    end

    context "when the client does not pass a user ID" do
      let(:user) do
        User.create(email: 'user@localhost')
      end

      let(:headers) do
        {
          "Accept" => "application/json",
          "Authorization" => "Bearer #{user.token}"
        }
      end

      before do
        user
      end

      after do
        user.destroy
      end

      it "denies the request" do
        get "/data_sets/latest/other", headers: headers

        expect(response.forbidden?).to be true
      end
    end

    context "when the client is authenticated via a token" do
      let(:user) do
        User.create(email: 'user@localhost')
      end

      let(:headers) do
        {
          "Accept" => "application/json",
          "Authorization" => "Bearer #{user.token}"
        }
      end

      let(:params) do
        {
          user: { id: user.id }
        }
      end

      before do
        user
        DataSet.create(report_time: today_end_of_hour, data: "abc123,def456", data_file: nil, status: true, category: "StaffDirectoryRemoved")
        DataSet.create(report_time: today_end_of_hour, data: "other5,other6", data_file: nil, status: false, category: "Other")
        DataSet.create(report_time: today, data: "other3,other4", data_file: nil, status: true, category: "Other")
        DataSet.create(report_time: previous_time, data: "other1,other2", data_file: nil, status: true, category: "Other")
      end

      it "returns the latest other dataset" do
        get "/data_sets/latest/other", headers: headers, params: params
        expect(response.body).to eq('other3,other4')
      end

      it "returns the StaffDirectoryRemoved dataset" do
        get "/data_sets/latest/staff-directory-removed", headers: headers, params: params
        expect(response.body).to eq('abc123,def456')
      end

      it "returns the data in a file for StaffDirectory" do
        Tempfile.create do |file|
          file.write("data from file\nMultiple lines")
          file.rewind
          DataSet.create(report_time: today, data: nil, data_file: file.path, status: true, category: "StaffDirectory")
          get "/data_sets/latest/staff-directory", headers: headers, params: params
          expect(response.body).to eq("data from file\nMultiple lines")
        end
      end
    end

    context "when the client is authenticated via cas" do
      let(:user) do
        User.create(email: 'user@localhost')
      end

      before do
        sign_in user
        DataSet.create(report_time: today_end_of_hour, data: "abc123,def456", data_file: nil, status: true, category: "StaffDirectoryRemoved")
        DataSet.create(report_time: today_end_of_hour, data: "other5,other6", data_file: nil, status: false, category: "Other")
        DataSet.create(report_time: today, data: "other3,other4", data_file: nil, status: true, category: "Other")
        DataSet.create(report_time: previous_time, data: "other1,other2", data_file: nil, status: true, category: "Other")
      end

      it "returns the latest other dataset" do
        get "/data_sets/latest/other"
        expect(response.body).to eq('other3,other4')
      end
    end
  end
end
