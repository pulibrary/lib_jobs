# frozen_string_literal: true
require 'rails_helper'

describe LibJobs::ArchivesSpace::Resource do
  subject(:resource) do
    described_class.new(resource_attributes.deep_symbolize_keys)
  end
  let(:resource_attributes) do
    { repository: repository }.merge(fixture_values)
  end
  let(:top_container) { instance_double(LibJobs::ArchivesSpace::TopContainer) }
  let(:top_containers) { [top_container] }
  let(:repository) { instance_double(LibJobs::ArchivesSpace::Repository) }
  let(:fixture_file_path) do
    Rails.root.join('spec', 'fixtures', 'archives_space', 'resource.json')
  end
  let(:fixture_json) do
    File.read(fixture_file_path)
  end
  let(:fixture_values) do
    JSON.parse(fixture_json)
  end

  describe '#ead_id' do
    it 'retrieves the EAD ID' do
      expect(resource.ead_id).to eq('ABID001')
    end
  end
end
