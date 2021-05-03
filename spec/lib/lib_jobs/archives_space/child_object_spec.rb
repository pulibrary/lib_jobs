# frozen_string_literal: true
require 'rails_helper'

describe LibJobs::ArchivesSpace::ChildObject do
  subject(:child_object) do
    described_class.new(child_object_attributes.deep_symbolize_keys)
  end

  let(:client) do
    instance_double(LibJobs::ArchivesSpace::Client)
  end
  let(:fixture_file_path) do
    Rails.root.join('spec', 'fixtures', 'archives_space', 'resource.json')
  end
  let(:fixture_json) do
    File.read(fixture_file_path)
  end
  let(:fixture_values) do
    JSON.parse(fixture_json)
  end
  let(:repository) do
    instance_double(LibJobs::ArchivesSpace::Repository)
  end
  let(:child_object_attributes) do
    fixture_values.merge(
      {
        client: client,
        repository: repository
      }
    )
  end

  describe '#repository' do
    let(:retrieved) { child_object.repository }

    context 'when the ID is passed to the constructor' do
      let(:repository_id) { '1' }
      let(:child_object_attributes) do
        fixture_values.merge(
          {
            client: client,
            repository: nil,
            repository_id: repository_id
          }
        )
      end

      it 'retrieves the Repository object from the API client' do
        allow(client).to receive(:find_repository_by).and_return(repository)

        expect(retrieved).to eq(repository)
        expect(client).to have_received(:find_repository_by).with(id: repository_id)
      end
    end

    context 'when the URI is passed to the constructor' do
      let(:repository_uri) { 'http://localhost:8089/repositories/1' }
      let(:child_object_attributes) do
        fixture_values.merge(
          {
            client: client,
            repository: nil,
            repository_uri: repository_uri
          }
        )
      end

      it 'retrieves the Repository object from the API client' do
        allow(client).to receive(:find_repository_by).and_return(repository)

        expect(retrieved).to eq(repository)
        expect(client).to have_received(:find_repository_by).with(uri: repository_uri)
      end
    end
  end

  describe '#update' do
    before do
      allow(repository).to receive(:update_child)
    end

    it 'delegates the update request to the parent Repository object' do
      child_object.update
      expect(repository).to have_received(:update_child).with(child: child_object, model_class: described_class)
    end

    context 'when the Repository Object is a nil value' do
      let(:repository) { nil }

      before do
        allow(client).to receive(:find_repository_by).and_return(nil)
      end

      it 'returns a nil value' do
        expect(child_object.update).to be nil
      end
    end
  end
end
