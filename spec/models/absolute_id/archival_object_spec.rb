# frozen_string_literal: true
require 'rails_helper'

RSpec.describe AbsoluteId::ArchivalObject, type: :model do
  subject(:archival_object) do
    described_class.new(
      uri: uri,
      json_resource: JSON.generate(json_resource)
    )
  end
  let(:level) { 'series' }
  let(:ref_id) { '836QX399J' }
  let(:title) { 'Archival Object Title' }
  let(:create_time) { '2021-01-23T18:03:11Z' }
  let(:system_mtime) { '2021-01-23T18:03:11Z' }
  let(:user_mtime) { '2021-01-23T18:03:11Z' }
  let(:repository_id) { '1' }
  let(:uri) { "http://localhost:8089/repositories/#{repository_id}/archival_objects/1" }
  let(:id) { '1' }
  let(:lock_version) { 1 }
  let(:json_resource) do
    {
      create_time: create_time,
      id: id,
      lock_version: lock_version,
      system_mtime: system_mtime,
      uri: uri,
      user_mtime: user_mtime,
      level: level,
      ref_id: ref_id,
      title: title
    }
  end

  describe '.resource_class' do
    it 'accesses the API object class' do
      expect(described_class.resource_class).to eq(LibJobs::ArchivesSpace::ArchivalObject)
    end
  end

  describe '#json_properties' do
    it 'generates the properties used for the ArchivalObject instance' do
      expect(archival_object.json_properties).to be_a(Hash)
      expect(archival_object.json_properties).to include(repository_id: repository_id)
      expect(archival_object.json_properties).to include(level: level)
      expect(archival_object.json_properties).to include(ref_id: ref_id)
      expect(archival_object.json_properties).to include(title: title)
    end
  end
end
