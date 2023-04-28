# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(AlmaSubmitCollection::HostRecord) do
  let(:constituent_ids) { ["9933584373506421", "997007993506421", "997008003506421"] }
  let(:host_file) { Pathname.new(file_fixture_path).join("alma", 'host_record.xml').to_s }
  let(:record) { MARC::XMLReader.new(host_file).first }
  before do
    stub_alma_bibs(ids: constituent_ids, status: 200, fixture: "constituent_records.xml", apikey: '1234')
  end
  describe('#constituent_records') do
    it('returns an array of MARC records') do
      constituent_records = described_class.new(record).constituent_records
      expect(constituent_records[0]['001'].value).to eq('9933584373506421')
      expect(constituent_records[1]['001'].value).to eq('997007993506421')
      expect(constituent_records[2]['001'].value).to eq('997008003506421')
    end
  end
end
