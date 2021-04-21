# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AbsoluteIds::Repositories::ContainersController do
  describe '#index' do
    it 'returns all available locations in a specific repository as JSON' do
      stub_aspace_login
      stub_location(location_id: 23_649)
      stub_repository(repository_id: "4")
      stub_repository_top_containers(repository_id: "4")

      get :index, params: { repository_id: "4" }, format: :json

      expect(response).to be_successful
      json = JSON.parse(response.body)
      # TODO: Fix this - it's a bug, containers aren't paging.
      expect(json.length).to eq 250
      expect(json[0]).to eq(
        {
          "create_time" => "2021-01-23T18:03:11Z",
          "id" => "57589",
          "lock_version" => 8,
          "system_mtime" => "2021-01-26T13:49:26Z",
          "uri" => "/repositories/4/top_containers/57589",
          "user_mtime" => "2021-01-25T03:48:14Z",
          "active_restrictions" => [],
          "barcode" => "32101092753035",
          "collection" => [{ "ref" => "/repositories/4/resources/1870", "identifier" => "AC001", "display_string" => "General Manuscripts Collection" }],
          "container_locations" =>
          [
            { "create_time" => "2021-01-22T22:29:47Z",
              "id" => "23649",
              "lock_version" => 0,
              "system_mtime" => "2021-01-22T22:29:47Z",
              "uri" => "/locations/23649",
              "user_mtime" => "2021-01-22T22:29:47Z",
              "area" => nil,
              "barcode" => nil,
              "building" => "Seeley G. Mudd Manuscript Library",
              "classification" => "mudd",
              "external_ids" => [],
              "floor" => nil,
              "functions" => [],
              "room" => nil,
              "temporary" => nil }
          ],
          "exported_to_ils" => nil,
          "ils_holding_id" => "AC001_i1",
          "ils_item_id" => nil,
          "indicator" => "3",
          "series" => [],
          "resources" => [],
          "type" => "box"
        }
      )
    end

    context "when something goes wrong" do
      it "returns an empty array" do
        stub_aspace_login
        stub_repository(repository_id: "4")
        stub_repository_top_containers(repository_id: "4", error: true)

        get :index, params: { repository_id: "4" }, format: :json

        expect(response).to be_successful
        json = JSON.parse(response.body)
        expect(json).to eq []
      end
    end

    context 'when authorizing via a bearer token' do
      it 'skips forgery' do
        stub_aspace_login
        stub_location(location_id: 23_649)
        stub_repository(repository_id: "4")
        stub_repository_top_containers(repository_id: "4")
        allow(controller).to receive(:verify_authenticity_token)

        request.headers['Authorization'] = 'Bearer 123'
        get :index, params: { repository_id: "4" }, format: :json

        expect(controller).not_to have_received(:verify_authenticity_token)
      end
    end
  end
end
