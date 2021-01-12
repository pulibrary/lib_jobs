# frozen_string_literal: true
require 'rails_helper'

describe LibJobs::ArchivesSpace::Resource do
  subject(:resource) do
    described_class.new(repository, fixture_values)
  end
  let(:top_container) { instance_double(LibJobs::ArchivesSpace::TopContainer) }
  let(:repository) { instance_double(LibJobs::ArchivesSpace::Repository) }
  let(:fixture_file_path) do
    Rails.root.join('spec', 'fixtures', 'archives_space_resource.json')
  end
  let(:fixture_json) do
    File.read(fixture_file_path)
  end
  let(:fixture_values) do
    JSON.parse(fixture_json)
  end

  before do
    allow(repository).to receive(:find_top_container).and_return(top_container)
  end

  describe '#instances' do
    it 'retrieves the instances' do
      expect(resource.instances).not_to be_empty
      expect(resource.instances.first).to be_a LibJobs::ArchivesSpace::Instance
      expect(resource.instances.first.sub_container).to be_a LibJobs::ArchivesSpace::SubContainer
      expect(resource.instances.first.top_container).to be top_container
      expect(resource.instances.first.sub_container.top_container).to be top_container
    end
  end
end
