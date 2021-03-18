# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AbsoluteIds::ContainerProfilesController do
  describe '#index' do
    it 'returns all available container profiles as JSON, including prefixes' do
      stub_aspace_login
      stub_container_profiles

      get :index, format: :json

      expect(response).to be_success
      json = JSON.parse(response.body)
      expect(json.length).to eq 13
      # TODO: Clarify what prefixes are. What are they?
      expect(json[0]["prefix"]).to eq "P"
      expect(json[0]["name"]).to eq "Elephant size box"
    end

    context "when authorizing via a bearer token" do
      it "skips forgery" do
        allow(controller).to receive(:verify_authenticity_token)
        stub_aspace_login
        stub_container_profiles

        request.headers["Authorization"] = "Bearer 123"
        get :index, format: :json

        expect(controller).not_to have_received(:verify_authenticity_token)
      end
    end
  end
end
