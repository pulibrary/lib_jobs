# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "AbsoluteIds::Repositories::Resources", type: :request do
  let(:repository_id) { '3' }

  let(:repository_fixture_file_path) do
    Rails.root.join('spec', 'fixtures', 'archivesspace_repository.json')
  end
  let(:repository_fixture) do
    # json = File.read(repository_fixture_file_path)
    # JSON.parse(json)
    File.read(repository_fixture_file_path)
  end

  let(:login_fixture_file_path) do
    Rails.root.join('spec', 'fixtures', 'archivesspace_login.json')
  end
  let(:login_fixture) do
    # json = File.read(login_fixture_file_path)
    # JSON.parse(json)
    File.read(login_fixture_file_path)
  end

  # let(:client) { instance_double(LibJobs::ArchivesSpace::Client) }
  let(:client) { LibJobs::ArchivesSpace::Client.default }

  let(:repository_response_status) { double }
  let(:repository_response) { double }

  before do
    allow(repository_response_status).to receive(:code).and_return("200")
    allow(repository_response).to receive(:status).and_return(repository_response_status)
    allow(repository_response).to receive(:body).and_return(repository_fixture)
    allow(client).to receive(:get).with("/repositories/#{repository_id}").and_return(repository_response)
    # allow(client).to receive(:find_repository).with(id: repository_id).and_return(repository)

    allow(client).to receive(:login).and_return(login_fixture)
    allow(LibJobs::ArchivesSpace::Client).to receive(:new).and_return(client)
  end

  describe "GET /absolute-ids/repositories/:repository_id/resources" do
    context "when requesting a JSON representation" do
      let(:headers) do
        {
          "Accept" => "application/json"
        }
      end

      let(:resources_fixture_file_path) do
        Rails.root.join('spec', 'fixtures', 'archivesspace_resources.json')
      end
      let(:resources_fixture) do
        # json = File.read(resources_fixture_file_path)
        # JSON.parse(json)
        File.read(resources_fixture_file_path)
      end
      let(:resources_response_status) { double }
      let(:resources_response) { double }

      before do
        allow(resources_response_status).to receive(:code).and_return("200")
        allow(resources_response).to receive(:status).and_return(resources_response_status)
        allow(resources_response).to receive(:body).and_return(resources_fixture)
        allow(client).to receive(:get).with("/repositories/#{repository_id}/resources?page=1&page_size=100000").and_return(resources_response)
        # allow(client).to receive(:get).with("/repositories/#{repository_id}/resources?page=1&page_size=100000").and_return(resources_fixture)
      end

      it "renders all existing ArchivesSpace Resources" do
        get "/absolute-ids/repositories/#{repository_id}/resources", headers: headers

        expect(response.content_type).to eq("application/json")
        expect(response.body).not_to be_empty
        json_response = JSON.parse(response.body)

        expect(json_response).to be_an(Array)
        expect(json_response).not_to be_empty
        resource_json = json_response.first
        expect(resource_json).to be_a(Hash)
        expect(resource_json).to include("id" => "MC001.04")
        expect(resource_json).to include("uri" => "http://localhost:8089/repositories/3/resources/1457")
        expect(resource_json).to include("title" => "American Civil Liberties Union Records: Subgroup 4")
      end
    end
  end
end
