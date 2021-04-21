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
      # stub_aspace_login
    end

    it 'retrieves the ArchivesSpace TopContainer' do
      top_container = repository.find_top_container_by(uri: top_container_uri)
      expect(top_container).to be_a LibJobs::ArchivesSpace::TopContainer
      expect(top_container.id).to eq(top_container_id)
    end
  end
end
