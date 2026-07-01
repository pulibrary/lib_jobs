# frozen_string_literal: true
require "rails_helper"

RSpec.describe "Library Events csv", type: :request do
  describe "GET /library-events" do
    it "returns a csv" do
      stub_request(:get, "https://libcal.princeton.edu/ical_subscribe.php?cid=12260&k=79a5e62a54")
        .to_return(status: 200, headers: {},
                   body: File.new(Rails.root.join('spec', 'fixtures', 'files', 'libcal_events.ics')))

      get "/library-events"
      expect(response).to be_successful
      expect(response.media_type).to eq 'text/csv'
      expect(response.body).to include 'This informal zoom conversation will start with a checklist on getting started with library services and collections.'
      expect { CSV.parse(response.body) }.not_to raise_error
    end
  end
end
