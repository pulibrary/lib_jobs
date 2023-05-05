# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(AlmaSubmitCollection::HostRecord) do
  let(:constituent_ids) { ["9933584373506421", "997007993506421", "997008003506421"] }
  let(:host_file) { Pathname.new(file_fixture_path).join("alma", 'host_record.xml').to_s }
  let(:host_record) { described_class.new(MARC::XMLReader.new(host_file).first) }
  let(:fields) do
    [
      { '001' => '12345' },
      { 'a24' => { 'subfields' => [{ 'a' => 'nah' }] } },
      { '902' => { 'subfields' => [{ 'a' => 'anything' }] } }
    ]
  end
  let(:leader) { '00426nad a2200133 i 4500' }
  let(:alma_record) { described_class.new(MARC::Record.new_from_hash('fields' => fields, 'leader' => leader)) }

  before do
    stub_alma_bibs(ids: constituent_ids, status: 200, fixture: "constituent_records.xml", apikey: '1234')
  end
  describe('#constituent_records') do
    it('returns an array of MARC records') do
      constituent_records = host_record.constituent_records
      expect(constituent_records[0]['001'].value).to eq('9933584373506421')
      expect(constituent_records[1]['001'].value).to eq('997007993506421')
      expect(constituent_records[2]['001'].value).to eq('997008003506421')
    end
  end

  describe('#fixed record') do
    it('is fixed using the record_fixes method') do
      fixed_record = alma_record.record_fixes
      expect(fixed_record['a24']).to be nil
      expect(fixed_record['902']).to be nil
    end
  end
end
