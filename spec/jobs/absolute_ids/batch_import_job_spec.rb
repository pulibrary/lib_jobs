# frozen_string_literal: true
require 'rails_helper'

RSpec.describe AbsoluteIds::BatchImportJob, type: :job do
  let(:barcode_entries) do
    [
      ["ID", "B", "Stamp"],
      ["8450", "32101080516626", "7/29/15"],
      ["8451", "32101080516618", "7/29/15"]
    ]
  end
  let(:sequence_entries) do
    [
      ["S",
       "fkBarcodes",
       "Size",
       "CollDes",
       "CollSeq",
       "Format",
       "Stamp",
       "User",
       "OK",
       "OKText",
       "SOrder",
       "CollectionCode",
       "Location",
       "AtType",
       "Output",
       "OutputStamp"],
      ["7374", "8450", "B", "0", "0", "None", "7/29/15", "msiravo", "TRUE", nil, "1", "Pams / NR / Chinese", "ctsn", nil, "TRUE", nil],
      ["7375", "8451", "B", "0", "0", "None", "7/29/15", "msiravo", "TRUE", nil, "2", "Pams / NR / Chinese", "ctsn", nil, "TRUE", nil]
    ]
  end
  let(:container_profile_id) { '2' }
  let(:repository_id) { '4' }
  let(:ead_id) { 'ABID001' }
  let(:resource_id) { '4188' }

  before do
    stub_aspace_login
    stub_container_profiles
    stub_locations
    stub_repositories
    stub_resource(repository_id: repository_id, resource_id: resource_id)
  end

  describe '.perform' do
    it 'imports the things' do
      described_class.perform_now(barcode_entries: barcode_entries, sequence_entries: sequence_entries)

      expect(AbsoluteId.all).not_to be_empty
      expect(AbsoluteId.all.length).to eq(2)
      expect(AbsoluteId.first.barcode).to be_a(AbsoluteIds::Barcode)
      expect(AbsoluteId.first.barcode.value).to eq("32101080516626")
      expect(AbsoluteId.first.batch).to be_a(AbsoluteId::Batch)
      expect(AbsoluteId.first.batch.session).to be_a(AbsoluteId::Session)
      expect(AbsoluteId.first.batch.user).to be_a(User)
      expect(AbsoluteId.first.batch.user.email).to eq('msiravo@princeton.edu')

      expect(AbsoluteId.last.barcode).to be_a(AbsoluteIds::Barcode)
      expect(AbsoluteId.last.barcode.value).to eq("32101080516618")
      expect(AbsoluteId.last.batch).to be_a(AbsoluteId::Batch)
      expect(AbsoluteId.last.batch).not_to eql(AbsoluteId.first.batch)
      expect(AbsoluteId.last.batch.session).to be_a(AbsoluteId::Session)
      expect(AbsoluteId.last.batch.session).to eql(AbsoluteId.first.batch.session)
      expect(AbsoluteId.last.batch.user).to be_a(User)
      expect(AbsoluteId.last.batch.user.email).to eq('msiravo@princeton.edu')
    end
  end
end
