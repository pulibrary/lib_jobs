# frozen_string_literal: true
require 'rails_helper'

describe LibJobs::ArchivesSpace::ResourceChildObject do
  subject(:resource_child_object) { described_class.new(resource_attributes.deep_symbolize_keys) }

  let(:top_container) { instance_double(LibJobs::ArchivesSpace::TopContainer) }
  let(:top_containers) { [top_container] }

  let(:repository) { instance_double(LibJobs::ArchivesSpace::Repository) }
  let(:fixture_file_path) do
    Rails.root.join('spec', 'fixtures', 'archives_space', 'resource_child.json')
  end
  let(:fixture_json) do
    File.read(fixture_file_path)
  end
  let(:fixture_values) do
    JSON.parse(fixture_json)
  end
  let(:resource_attributes) do
    fixture_values.merge(
      {
        repository: repository
      }
    )
  end

  describe '#instances' do
    it 'accesses the Instance objects related to the parent object' do
      expect(resource_child_object.instances).not_to be_empty
      expect(resource_child_object.instances.first).to be_a(LibJobs::ArchivesSpace::Instance)
    end
  end
end
