# frozen_string_literal: true
require "rails_helper"

RSpec.describe AlmaPeople::AlmaQueryPersonCSV do
  subject(:feed) { described_class.new(csv_file: Rails.root.join("spec", "fixtures", 'alma_users_future_exp_no_netid_test.csv')) }
  let(:token) { instance_double("AccessToken") }

  let(:body) { '[ ]' }

  describe "get_json" do
    it "gets the data from the csv file in OIT feed format" do
      json_data = feed.get_json
      expect(json_data.count).to eq(1)
      expect(json_data.first).to eq({ "CAMPUS_ID" => "lehs", "EMPLID" => "/1/243166d", "PVPATRONGROUP" => "SENR", "PATRON_EXPIRATION_DATE" => "2014-01-31", "PATRON_PURGE_DATE" => "2014-01-31",
                                      "PRF_OR_PRI_FIRST_NAM" => "/1/2D Fleh", "PRF_OR_PRI_LAST_NAME" => "middle", "PRF_OR_PRI_MIDDLE_NAME" => "Lehs 11/1/", "PU_BARCODE" => "999111000" })
    end
  end
end
