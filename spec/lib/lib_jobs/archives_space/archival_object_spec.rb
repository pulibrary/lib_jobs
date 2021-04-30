# frozen_string_literal: true
require 'rails_helper'

describe LibJobs::ArchivesSpace::ArchivalObject do
  subject(:archival_object) do
    described_class.new(archival_object_attributes.deep_symbolize_keys)
  end
  let(:archival_object_attributes) do
    { repository: repository }.merge(fixture_values)
  end

  let(:top_container) { instance_double(LibJobs::ArchivesSpace::TopContainer) }
  let(:top_containers) { [top_container] }
  let(:repository) { instance_double(LibJobs::ArchivesSpace::Repository) }
  let(:fixture_file_path) do
    Rails.root.join('spec', 'fixtures', 'archives_space', 'archival_object.json')
  end
  let(:fixture_json) do
    File.read(fixture_file_path)
  end
  let(:fixture_values) do
    JSON.parse(fixture_json)
  end

  describe '.model_class' do
    it 'accesses the ActiveRecord Model' do
      expect(described_class.model_class).to eq(AbsoluteId::ArchivalObject)
    end
  end

  describe '#ref_id' do
    it 'accesses the API reference ID' do
      expect(archival_object.ref_id).to eq('ABID001_c98233-65452')
    end
  end

  describe '#attributes' do
    it 'generates the attributes for the JSON serialized Object' do
      expect(archival_object.attributes).to include(
        create_time: "2021-02-25T14:40:11Z",
        id: "1446370",
        lock_version: 1,
        system_mtime: "2021-03-10T15:43:38Z",
        uri: "/repositories/4/archival_objects/1446370",
        user_mtime: "2021-02-25T14:40:11Z",
        title: "Ut enim ad minim veniam",
        level: "file",
        ref_id: "ABID001_c98233-65452"
      )
      expect(archival_object.attributes).to include(:instances)
      expect(archival_object.attributes[:instances]).not_to be_empty
    end
  end
end
