# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "AbsoluteIds::Repositories::Resources", type: :request do
  let(:repository_id) { '4' }

  describe "GET /absolute-ids/repositories/:repository_id/resources/" do
    context "when requesting a JSON representation" do
      let(:user) { create(:user) }
      let(:headers) do
        {
          "Accept" => "application/json",
          "Authorization" => "Bearer #{user.token}"
        }
      end
      let(:client) do
        stub_aspace_repository(repository_id: repository_id)
      end

      before do
        allow(LibJobs::ArchivesSpace::Client).to receive(:source).and_return(client)
      end

      it "renders all existing ArchivesSpace Resources for a given Repository" do
        get "/absolute-ids/repositories/#{repository_id}/resources/", headers: headers

        expect(response.content_type).to eq("application/json")
        expect(response.body).not_to be_empty
        json_response = JSON.parse(response.body)

        expect(json_response).to be_an(Array)
        expect(json_response).not_to be_empty
        resource_json = json_response.first
        expect(resource_json).to be_a(Hash)

        expect(resource_json).to include("id" => "1870")
        expect(resource_json).to include("lock_version" => 4)
        expect(resource_json).to include("uri" => "/repositories/4/resources/1870")
        expect(resource_json).to include("title" => "General Manuscripts Collection")
        expect(resource_json).to include("level" => "collection")
        expect(resource_json).to include("ead_id" => "AC001")

        expect(resource_json).to include("create_time")
        expect(resource_json["create_time"]).not_to be_empty
        expect(resource_json).to include("system_mtime")
        expect(resource_json["system_mtime"]).not_to be_empty
        expect(resource_json).to include("user_mtime")
        expect(resource_json["user_mtime"]).not_to be_empty
      end
    end
  end
end
