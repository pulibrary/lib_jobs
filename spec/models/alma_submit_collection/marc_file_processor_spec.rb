# frozen_string_literal: true
require 'rails_helper'

RSpec.describe AlmaSubmitCollection::MarcFileProcessor, type: :model do
  let(:filename) { 'host_record.xml' }
  let(:processor) { described_class.new(file: File.new(Pathname.new(file_fixture_path).join("alma", filename))) }
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
end
