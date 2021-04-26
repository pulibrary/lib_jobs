# frozen_string_literal: true
require 'rails_helper'

RSpec.describe AbsoluteIds::Importer do
  subject(:importer) do
    described_class.new(barcode_csv_path: barcode_csv_path, sequence_csv_path: sequence_csv_path)
  end
  let(:barcode_csv_path) { Rails.root.join('spec', 'fixtures', 'archives_space', 'imports', 'barcode_entries.csv') }
  let(:sequence_csv_path) { Rails.root.join('spec', 'fixtures', 'archives_space', 'imports', 'sequence_entries.csv') }
  let(:repository_id) { '4' }
  let(:resource_id) { '4188' }

  describe '#import' do
    before do
      stub_aspace_login
      stub_container_profiles
      stub_locations
      stub_repositories
      stub_resource(repository_id: repository_id, resource_id: resource_id)
    end

    it 'imports the CSV rows as new AbID models' do
      expect(AbsoluteId.all).to be_empty
      importer.import

      expect(AbsoluteId.all).not_to be_empty
      expect(AbsoluteId.all.length).to eq(2)

      expect(AbsoluteId.first.value).to eq("32101080516626")
      expect(AbsoluteId.first.location).to eq("ctsn")
      expect(AbsoluteId.first.container_profile).to be_a(Hash)
      expect(AbsoluteId.first.container_profile).to include(id: "3", lock_version: 92_585, uri: "/container_profiles/3", name: "NBox", prefix: nil)
      expect(AbsoluteId.first.repository).to eq("ctsn")
      expect(AbsoluteId.first.resource).to eq("Pams / NR / Chinese")
      expect(AbsoluteId.first.container).to eq("1")

      expect(AbsoluteId.last.value).to eq("32101080516618")
      expect(AbsoluteId.last.location).to eq("ctsn")
      expect(AbsoluteId.last.container_profile).to be_a(Hash)
      expect(AbsoluteId.last.container_profile).to include(id: "3", lock_version: 92_585, uri: "/container_profiles/3", name: "NBox", prefix: nil)
      expect(AbsoluteId.last.repository).to eq("ctsn")
      expect(AbsoluteId.last.resource).to eq("Pams / NR / Chinese")
      expect(AbsoluteId.last.container).to eq("2")
    end
  end
end
