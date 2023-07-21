# frozen_string_literal: true
require 'rails_helper'

RSpec.describe AlmaSubmitCollection::MarcFileProcessor, type: :model do
  let(:filename) { 'host_record.xml' }
  let(:processor) { described_class.new(file: File.new(Pathname.new(file_fixture_path).join("alma", filename))) }
  let(:constituent_ids) { ["9933584373506421", "997007993506421", "997008003506421"] }
  before do
    stub_alma_bibs(ids: constituent_ids, status: 200, fixture: "constituent_records.xml", apikey: '1234')
  end
  context "when the file has valid MARC records" do
    it 'processed all valid records in a file' do
      processor.process
      expect(processor.records_processed).to eq(8)
    end
  end
  context "when the file has invalid MARC records" do
    let(:filename) { 'record_without_852.xml' }
    it 'does not process the invalid records' do
      processor.process
      expect(processor.records_processed).to eq(0)
    end
  end

  describe "#constituent_record_file" do
    let(:constituent_ids) { ["9933584373506421", "997007993506421", "997008003506421"] }
    it 'contains constituent records taken from the Alma API' do
      stub_alma_bibs(ids: constituent_ids, status: 200, fixture: "constituent_records.xml", apikey: '1234')
      processor.process
      processor.constituent_record_file.rewind
      @reader = MARC::XMLReader.new(processor.constituent_record_file)
      expect(@reader.first['245']['a']).to eq('Presse scientifiques des deux mondes')
    end
  end
end
