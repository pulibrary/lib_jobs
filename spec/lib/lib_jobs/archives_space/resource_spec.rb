# frozen_string_literal: true
require 'rails_helper'

describe LibJobs::ArchivesSpace::Resource do
  subject(:resource) do
    described_class.new(resource_attributes.deep_symbolize_keys)
  end
  let(:resource_attributes) do
    fixture_values.merge(
      { repository: repository }
    )
  end
  let(:barcode1) { 'barcode1' }
  let(:top_container1) { instance_double(LibJobs::ArchivesSpace::TopContainer) }
  let(:barcode2) { 'barcode2' }
  let(:top_container2) { instance_double(LibJobs::ArchivesSpace::TopContainer) }
  let(:top_containers) { [top_container1, top_container2] }
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

  before do
    allow(top_container2).to receive(:barcode).and_return(barcode2)
    allow(top_container1).to receive(:barcode).and_return(barcode1)
    allow(top_container2).to receive(:id).and_return(2)
    allow(top_container1).to receive(:id).and_return(1)
    allow(repository).to receive(:search_top_container_children_by).and_return(top_containers)
  end

  describe '.model_class_exists?' do
    it 'asserts that the ActiveRecord Class exists' do
      expect(described_class.model_class_exists?).to be true
    end
  end

  describe '#ead_id' do
    it 'retrieves the EAD ID' do
      expect(resource.ead_id).to eq('ABID001')
    end
  end

  describe '#search_top_containers_by' do
    it 'retrieves the TopContainers' do
      found = resource.search_top_containers_by(index: 1)

      expect(found.length).to eq(1)
      expect(found.first).to eq(top_container1)
    end

    context 'when overriding the caching for search results' do
      it 'retrieves the TopContainers' do
        resource.search_top_containers_by(index: 1, cache: false)
        found = resource.search_top_containers_by(index: 1, cache: false)

        expect(repository).to have_received(:search_top_container_children_by).twice
        expect(found.length).to eq(1)
        expect(found.first).to eq(top_container1)
      end
    end
  end

  describe '#barcodes' do
    it 'accesses the barcodes for all child TopContainers' do
      expect(resource.barcodes).to eq([barcode1, barcode2])
    end
  end

  describe '#barcodes=' do
    let(:barcode4) { 'barcode4' }
    let(:barcode3) { 'barcode3' }

    before do
      allow(repository).to receive(:bulk_update_barcodes)
      allow(top_container2).to receive(:barcode).and_return(barcode4)
      allow(top_container1).to receive(:barcode).and_return(barcode3)
      allow(repository).to receive(:search_top_container_children_by).and_return(top_containers)

      resource.barcodes = [barcode3, barcode4]
    end

    it 'updates the barcodes for all child TopContainers' do
      expect(resource.barcodes).to eq([barcode3, barcode4])
    end
  end
end
