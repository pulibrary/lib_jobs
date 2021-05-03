# frozen_string_literal: true
require 'rails_helper'

describe LibJobs::ArchivesSpace::Repository do
  subject(:repository) do
    described_class.new(client: client, id: id)
  end

  let(:client) do
    LibJobs::ArchivesSpace::Client.source
  end
  let(:id) { '4' }
  let(:top_container_id) { '13' }
  let(:resource_id) { '4188' }
  let(:resource_uri) { "/repositories/#{id}/resources/#{resource_id}" }
  let(:top_container_uri) do
    "/repositories/#{id}/top_containers/#{top_container_id}"
  end
  let(:ead_id) { 'ABID001' }

  before do
    stub_location(location_id: '23640')
    stub_top_containers(ead_id: ead_id, repository_id: id)

    stub_resource(repository_id: id, resource_id: resource_id)
    stub_aspace_login
  end

  describe '#find_resource' do
    let(:id) { '4' }

    before do
      stub_search_repository_children(repository_id: id, type: 'top_container')
    end

    it 'retrieves the ArchivesSpace Resource' do
      resource = repository.find_resource(uri: resource_uri)
      expect(resource).to be_a LibJobs::ArchivesSpace::Resource
      expect(resource.id).to eq(resource_id)
    end
  end

  describe '#find_top_container_by' do
    before do
      stub_top_container(repository_id: id, top_container_id: top_container_id)
    end

    it 'retrieves the ArchivesSpace TopContainer' do
      top_container = repository.find_top_container_by(uri: top_container_uri)
      expect(top_container).to be_a LibJobs::ArchivesSpace::TopContainer
      expect(top_container.id).to eq(top_container_id)
    end
  end

  describe '#find_archival_object_by' do
    let(:id) { '4' }
    let(:archival_object_id) { '1446368' }
    let(:uri) { "/repositories/#{id}/archival_objects/#{archival_object_id}" }
    let(:resource_fixture_path) do
      Rails.root.join('spec', 'fixtures', 'archives_space', 'resource.json')
    end
    let(:resource_fixture) do
      File.read(resource_fixture_path)
    end
    let(:resource) do
      JSON.parse(resource_fixture)
    end

    before do
      stub_archival_object(repository_id: id, archival_object_id: archival_object_id)
    end

    it 'retrieves the ArchivalObject using the URI' do
      found = repository.find_archival_object_by(resource: resource, uri: uri)

      expect(found).to be_an(LibJobs::ArchivesSpace::ArchivalObject)
      expect(found.uri).to eq(uri)
    end
  end

  describe '#bulk_update_barcodes' do
    let(:barcode) { '32101092753035' }
    let(:top_container_id) { '57589' }
    let(:update_values) do
      {
        top_container_id => barcode.to_s
      }
    end

    before do
      stub_request(:post, "#{client.base_uri}/repositories/4/top_containers/bulk/barcodes")
      stub_top_container(repository_id: id, top_container_id: top_container_id)
      stub_aspace_login
    end

    it 'transmits a POST request to update barcodes for TopContainers' do
      repository.bulk_update_barcodes(update_values)

      expect(a_request(:post, "#{client.base_uri}/repositories/4/top_containers/bulk/barcodes").with(
        body: update_values.to_json,
        headers: {
          'Content-Type' => 'application/json'
        }
      )).to have_been_made
    end
  end

  describe '#update_top_container' do
    let(:top_container) do
      LibJobs::ArchivesSpace::TopContainer.new(
        id: 'test-id',
        repository: repository,
        container_locations: []
      )
    end

    context 'when an error is encountered requesting an update to a TopContainer' do
      let(:response_body) do
        {
          foo: {
            bar: 'baz'
          }
        }
      end

      before do
        stub_request(:post, "#{client.base_uri}/repositories/4/top_containers/test-id").to_return(
          status: 400,
          headers: {
            'Content-Type' => 'application/json'
          },
          body: response_body.to_json
        )
      end

      it 'raises an error' do
        expect { repository.update_top_container(top_container) }.to raise_error(LibJobs::ArchivesSpace::UpdateRecordError, 'baz')
      end
    end

    context 'when the requested TopContainer cannot be found' do
      before do
        stub_request(:post, "#{client.base_uri}/repositories/4/top_containers/test-id").to_return(
          status: 404
        )
      end

      it 'raises an error' do
        expect { repository.update_top_container(top_container) }.to raise_error(LibJobs::ArchivesSpace::UpdateRecordError, 'Resource not found for /repositories/4/top_containers/test-id')
      end
    end
  end
end
