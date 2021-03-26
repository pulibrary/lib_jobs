# frozen_string_literal: true
require 'rails_helper'

RSpec.describe AbsoluteIds::SessionSynchronizeJob, type: :job do
  describe '#perform' do
    let(:user) { create(:user) }

    let(:barcode) { '32101103191142' }
    let(:container_profile) do
      {
        create_time: "2021-01-21T20:10:59Z",
        id: "2",
        lock_version: 873,
        system_mtime: "2021-01-25T05:10:46Z",
        uri: "/container_profiles/2",
        user_mtime: "2021-01-21T20:10:59Z",
        name: "Elephant size box",
        size: "P"
      }
    end
    let(:location) do
      {
        create_time: "2021-01-22T22:29:46Z",
        id: "23640",
        lock_version: 0,
        system_mtime: "2021-01-22T22:29:47Z",
        uri: "/locations/23640",
        user_mtime: "2021-01-22T22:29:46Z",
        area: "Annex B",
        barcode: nil,
        building: "Annex",
        classification: "anxb",
        external_ids: [],
        floor: nil,
        functions: [],
        room: nil,
        temporary: nil
      }
    end
    let(:repository) do
      {
        create_time: "2016-06-27T14:10:42Z",
        id: repository_id,
        lock_version: 1,
        system_mtime: "2021-01-22T22:20:30Z",
        uri: "/repositories/4",
        user_mtime: "2021-01-22T22:20:30Z",
        name: "University Archives",
        repo_code: "univarchives"
      }
    end
    let(:repository_id) { '4' }
    let(:resource_fixture_path) do
      Rails.root.join('spec', 'fixtures', 'archives_space', 'resource.json')
    end
    let(:resource_fixture) do
      File.read(resource_fixture_path)
    end
    let(:resource) do
      JSON.parse(resource_fixture)
    end
    let(:resource_id) { 'ABID001' }
    let(:container_fixture_path) do
      Rails.root.join('spec', 'fixtures', 'archives_space', 'top_container.json')
    end
    let(:container_fixture) do
      File.read(container_fixture_path)
    end
    let(:container) do
      JSON.parse(container_fixture)
    end
    let(:model_attributes) do
      {
        value: barcode,
        location: location.to_json,
        container_profile: container_profile.to_json,
        repository: repository.to_json,
        resource: resource.to_json,
        container: container.to_json
      }
    end
    let(:absolute_id) { create(:absolute_id, model_attributes) }
    let(:barcode_unique) { true }
    let(:sync_client) do
      stubbed_client = stub_aspace_sync_client
      stubbed_client = stub_aspace_location(location_id: 23_640, client: stubbed_client)
      stubbed_client = stub_aspace_search_top_containers(repository_id: 4, barcode: 32_101_103_191_142, empty: barcode_unique, client: stubbed_client)
      stubbed_client = stub_aspace_top_container(repository_id: 4, top_container_id: 118_091, client: stubbed_client)
      stubbed_client = stub_aspace_repository(repository_id: 4, client: stubbed_client)
      stubbed_client = stub_aspace_resource(repository_id: 4, resource_id: 4188, client: stubbed_client)
      stubbed_client
    end
    let(:source_client) do
      stubbed_client = stub_aspace_source_client
      stubbed_client = stub_aspace_location(location_id: 23_640, client: stubbed_client)
      stubbed_client = stub_aspace_search_top_containers(repository_id: 4, barcode: 32_101_103_191_142, empty: barcode_unique, client: stubbed_client)
      stubbed_client = stub_aspace_top_container(repository_id: 4, top_container_id: 118_091, client: stubbed_client)
      stubbed_client = stub_aspace_repository(repository_id: 4, client: stubbed_client)
      stubbed_client = stub_aspace_resource(repository_id: 4, resource_id: 4188, client: stubbed_client)
      stubbed_client
    end
    let(:post_params) do
      {
        jsonmodel_type: "top_container",
        lock_version: 4,
        active_restrictions: [],
        container_locations: [],
        series: [],
        collection: [
          {
            ref: "/repositories/4/resources/4188",
            identifier: "ABID001",
            display_string: "AbID Testing Resource #1"
          }
        ],
        indicator: "P-000000",
        type: "box",
        barcode: "32101103191142",
        ils_holding_id: nil,
        ils_item_id: nil,
        exported_to_ils: nil
      }
    end
    let(:top_containers_search_fixture_path) do
      Rails.root.join('spec', 'fixtures', 'archives_space', 'repositories_top_containers_search.json')
    end
    let(:top_containers_search_fixture) do
      File.read(top_containers_search_fixture_path)
    end

    before do
      stub_request(:get, "#{sync_client.base_uri}/repositories/4/top_containers/search?q=32101103191142").to_return(body: top_containers_search_fixture)
      stub_request(:post, "#{sync_client.base_uri}/repositories/4/top_containers/118091")
      allow(LibJobs::ArchivesSpace::Client).to receive(:sync).and_return(sync_client)
      allow(LibJobs::ArchivesSpace::Client).to receive(:source).and_return(source_client)
    end

    it 'updates the ArchivesSpace TopContainer indicator and barcode fields with that of the AbId' do
      described_class.perform_now(user_id: user.id, model_id: absolute_id.id)

      expect(a_request(:post, "#{sync_client.base_uri}/repositories/4/top_containers/118091").with(
        body: post_params,
        headers: {
          'Content-Type' => 'application/json'
        }
      )).to have_been_made
    end

    context 'when a TopContainer has already using an existing barcode' do
      let(:logger) { instance_double(ActiveSupport::Logger) }
      let(:barcode_unique) { false }

      before do
        allow(logger).to receive(:warn)
        allow(Rails).to receive(:logger).and_return(logger)
      end

      it 'fails to update the ArchivesSpace TopContainer and raises an error' do
        described_class.perform_now(user_id: user.id, model_id: absolute_id.id)

        expect(a_request(:post, "#{sync_client.base_uri}/repositories/4/top_containers/118091").with(
          body: post_params,
          headers: {
            'Content-Type' => 'application/json'
          }
        )).not_to have_been_made

        expect(logger).to have_received(:warn).with("Warning: Failed to synchronize #{absolute_id.label}: Barcode #{absolute_id.barcode.value} is already used in ArchivesSpace.")
      end
    end
  end
end
