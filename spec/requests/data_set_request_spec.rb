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
      expect(response.body).to include('<td>StaffDirectoryRemoved</td>').once
      expect(response.body).to include('<td>StaffDirectoryAdded</td>').once
      expect(response.body).to include('<td>Other</td>').once
    end

    it "can be filtered by category" do
      get "/?category=StaffDirectoryAdded"
      expect(response.body).to include(previous_time.to_s).once
      expect(response.body).not_to include('<td>StaffDirectoryRemoved</td>')
      expect(response.body).to include('<td>StaffDirectoryAdded</td>').once
    end

    it "can be filtered by date" do
      get "/?report_date=#{today_string}"
      expect(response.body).to include(today_string).twice
      expect(response.body).to include('<td>StaffDirectoryRemoved</td>').once
      expect(response.body).not_to include('<td>StaffDirectoryAdded</td>')
      expect(response.body).to include('<td>Other</td>').once
    end

    it "can be filtered by an exact time" do
      get "/?report_time=#{today_time_string}"
      expect(response.body).to include(today_string).once
      expect(response.body).to include('<td>StaffDirectoryRemoved</td>').once
      expect(response.body).not_to include('<td>StaffDirectoryAdded</td>')
    end
  end
end
