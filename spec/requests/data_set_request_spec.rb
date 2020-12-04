# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "DataSets", type: :request do
  let(:yesterday) { DateTime.yesterday.midnight }
  let(:yesterday_string) { yesterday.strftime('%Y-%m-%d') }
  let(:today) { DateTime.now.midnight }
  let(:today_string) { today.strftime('%Y-%m-%d') }
  let(:today_end_of_hour) { today.end_of_hour }
  let(:today_time_string) { today.strftime('%Y-%m-%d %H:%M:%S %Z') }

  describe "index" do
    before do
      DataSet.create(report_time: today, data: "abc123,def456", data_file: nil, category: "StaffDirectoryRemoved")
      DataSet.create(report_time: today_end_of_hour, data: "abc123,def456", data_file: nil, category: "Other")
      DataSet.create(report_time: yesterday, data: "zzz999,yyy888", data_file: nil, category: "StaffDirectoryAdded")
    end
    it "returns all the datasets" do
      get "/"
      expect(response.body).to include(yesterday_string).once
      expect(response.body).to include(today_string).twice
      expect(response.body).to include('StaffDirectoryRemoved').once
      expect(response.body).to include('StaffDirectoryAdded').once
      expect(response.body).to include('Other').once
    end

    it "can be filtered by category" do
      get "/?category=StaffDirectoryAdded"
      expect(response.body).to include(yesterday_string).once
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
end
