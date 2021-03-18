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
      container_profile = json[0]
      expect(container_profile["create_time"]).to be_present
      expect(container_profile["id"]).to eq "2"
      expect(container_profile["lock_version"]).to eq 873
      expect(container_profile["system_mtime"]).to be_present
      expect(container_profile["uri"]).to eq "/container_profiles/2"
      expect(container_profile["user_mtime"]).to be_present
      # Prefixes are the container profile equivalent in the legacy AbID
      # database. We keep them here for cross-referencing.
      expect(container_profile["prefix"]).to eq "P"
      expect(container_profile["name"]).to eq "Elephant size box"
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
