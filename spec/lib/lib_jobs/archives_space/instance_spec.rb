# frozen_string_literal: true
require 'rails_helper'

describe LibJobs::ArchivesSpace::Instance do
  subject(:instance) do
    described_class.new(instance_attributes.deep_symbolize_keys)
  end

  let(:fixture_file_path) do
    Rails.root.join('spec', 'fixtures', 'archives_space', 'instance.json')
  end
  let(:fixture_json) do
    File.read(fixture_file_path)
  end
  let(:fixture_values) do
    JSON.parse(fixture_json)
  end

  let(:sub_container_fixture_file_path) do
    Rails.root.join('spec', 'fixtures', 'archives_space', 'sub_container.json')
  end
  let(:sub_container_fixture_json) do
    File.read(sub_container_fixture_file_path)
  end
  let(:sub_container_fixture_values) do
    JSON.parse(sub_container_fixture_json)
  end
  let(:sub_container) { LibJobs::ArchivesSpace::SubContainer.new(sub_container_fixture_values.deep_symbolize_keys) }

  let(:top_container_fixture_file_path) do
    Rails.root.join('spec', 'fixtures', 'archives_space', 'top_container.json')
  end
  let(:top_container_fixture_json) do
    File.read(top_container_fixture_file_path)
  end
  let(:top_container_fixture_values) do
    JSON.parse(top_container_fixture_json)
  end
  let(:top_container) { LibJobs::ArchivesSpace::TopContainer.new(top_container_fixture_values.deep_symbolize_keys) }

  let(:repository) { instance_double(LibJobs::ArchivesSpace::Repository) }
  let(:instance_attributes) do
    fixture_values.merge(
      {
        repository: repository
      }
    )
  end

  describe '#sub_container' do
    it 'accesses the SubContainer object' do
      expect(instance.sub_container).to be_a(LibJobs::ArchivesSpace::SubContainer)
    end
  end
  describe '#sub_container=' do
    let(:fixture_values) do
      JSON.parse(fixture_json).reject { |k, _v| k == "sub_container" }
    end

    it 'assigns the SubContainer object' do
      expect(instance.sub_container).to be nil

      instance.sub_container = sub_container
      expect(instance.sub_container).to be_a(LibJobs::ArchivesSpace::SubContainer)
    end
  end
  describe '#top_container' do
    before do
      allow(repository).to receive(:find_top_container_by).and_return(top_container)
    end

    it 'accesses the TopContainer object' do
      expect(instance.top_container).to be_a(LibJobs::ArchivesSpace::TopContainer)
      expect(instance.top_container.uri).to eq('/repositories/4/top_containers/118091')
    end
  end
end
