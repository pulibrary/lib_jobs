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
      let(:id) { '4188' }
      let(:ead_id) { 'AC001' }

      before do
        stub_location(location_id: '23640')
        stub_top_containers(ead_id: ead_id, repository_id: repository_id)
        stub_resources(repository_id: repository_id)
        stub_resource_find_by_id(repository_id: repository_id, identifier: id, resource_id: id)
        stub_repository(repository_id: repository_id)
        stub_resource(repository_id: repository_id, resource_id: id)
        stub_aspace_login
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

      context "when an error is encountered retrieving the Resources" do
        let(:logger) { instance_double(ActiveSupport::Logger) }

        before do
          allow(LibJobs::ArchivesSpace::Client).to receive(:source).and_raise(StandardError)
          allow(logger).to receive(:info)
          allow(logger).to receive(:warn)
          allow(Rails).to receive(:logger).and_return(logger)
        end

        it "returns an empty JSON array and logs an error" do
          get "/absolute-ids/repositories/#{repository_id}/resources/", headers: headers

          expect(response.content_type).to eq("application/json")
          expect(response.body).not_to be_empty
          json_response = JSON.parse(response.body)

          expect(json_response).to be_an(Array)
          expect(json_response).to be_empty

          expect(logger).to have_received(:warn).with('Failed to resolve the resources for the repository 4: StandardError')
        end
      end
    end
  end

  describe "GET /absolute-ids/repositories/:repository_id/resources/:resource_id" do
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
      let(:id) { '4188' }
      let(:ead_id) { 'ABID001' }

      before do
        stub_location(location_id: '23640')
        stub_top_containers(ead_id: ead_id, repository_id: repository_id)

        stub_resource_find_by_id(repository_id: repository_id, identifier: id, resource_id: id)
        stub_repository(repository_id: repository_id)
        stub_resource(repository_id: repository_id, resource_id: id)
        stub_aspace_login
      end

      it "renders an ArchivesSpace Resource for a given Repository" do
        get "/absolute-ids/repositories/#{repository_id}/resources/#{id}", headers: headers

        expect(response.content_type).to eq("application/json")
        expect(response.body).not_to be_empty
        json_response = JSON.parse(response.body)

        resource_json = json_response
        expect(resource_json).to be_a(Hash)

        expect(resource_json).to include("id" => "4188")
        expect(resource_json).to include("lock_version" => 1)
        expect(resource_json).to include("uri" => "/repositories/4/resources/4188")
        expect(resource_json).to include("title" => "AbID Testing Resource #1")
        expect(resource_json).to include("level" => "collection")
        expect(resource_json).to include("ead_id" => "ABID001")

        expect(resource_json).to include("create_time")
        expect(resource_json["create_time"]).not_to be_empty
        expect(resource_json).to include("system_mtime")
        expect(resource_json["system_mtime"]).not_to be_empty
        expect(resource_json).to include("user_mtime")
        expect(resource_json["user_mtime"]).not_to be_empty
      end

      context "when an error is encountered retrieving the Resource" do
        let(:logger) { instance_double(ActiveSupport::Logger) }

        before do
          allow(LibJobs::ArchivesSpace::Client).to receive(:source).and_raise(StandardError)
          allow(logger).to receive(:info)
          allow(logger).to receive(:warn)
          allow(Rails).to receive(:logger).and_return(logger)
        end

        it "returns an empty JSON array and logs an error" do
          get "/absolute-ids/repositories/#{repository_id}/resources/#{id}", headers: headers

          expect(response.content_type).to eq("application/json")
          expect(response.body).not_to be_empty
          json_response = JSON.parse(response.body)

          expect(json_response).to be nil

          expect(logger).to have_received(:warn).with("Failed to resolve the resource #{id} for the repository #{repository_id}: StandardError")
        end
      end
    end
  end

  describe "GET /absolute-ids/repositories/:repository_id/resources/search" do
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
      let(:id) { '4188' }
      let(:ead_id) { 'ABID001' }
      let(:params) do
        {
          eadId: ead_id
        }
      end

      before do
        stub_location(location_id: '23640')
        stub_resource_find_by_id(repository_id: repository_id, identifier: ead_id, resource_id: id)
        stub_top_containers(ead_id: ead_id, repository_id: repository_id)

        stub_resource_find_by_id(repository_id: repository_id, identifier: id, resource_id: id)
        stub_repository(repository_id: repository_id)
        stub_resource(repository_id: repository_id, resource_id: id)
        stub_aspace_login
      end

      it "retrieves all matching Resources for a given search query" do
        post "/absolute-ids/repositories/#{repository_id}/resources/search", headers: headers, params: params

        expect(response.content_type).to eq("application/json")
        expect(response.body).not_to be_empty
        json_response = JSON.parse(response.body)

        expect(json_response).to include(
          "id" => "4188",
          "uri" => "/repositories/4/resources/4188",
          "title" => "AbID Testing Resource #1",
          "level" => "collection",
          "ead_id" => "ABID001"
        )
      end

      context 'when an error is encountered trying to search for the Resource' do
        let(:logger) { instance_double(ActiveSupport::Logger) }

        before do
          allow(LibJobs::ArchivesSpace::Client).to receive(:source).and_raise(StandardError)
          allow(logger).to receive(:info)
          allow(logger).to receive(:warn)
          allow(Rails).to receive(:logger).and_return(logger)
        end

        it "returns a null result and logs a result" do
          post "/absolute-ids/repositories/#{repository_id}/resources/search", headers: headers, params: params

          expect(response.content_type).to eq("application/json")
          expect(response.body).not_to be_empty
          json_response = JSON.parse(response.body)
          expect(json_response).to be nil
        end
      end
    end
  end
end
