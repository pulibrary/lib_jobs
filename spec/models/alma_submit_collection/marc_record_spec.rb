# frozen_string_literal: true
require 'rails_helper'

RSpec.describe(AlmaSubmitCollection::MarcRecord) do
  let(:field_852_subfield_c) { 'pa' }
  let(:field_852_subfield_8) { '22922994580006421' }
  let(:field_876_subfield_a) { '23579686040006421' }
  let(:field_876_subfield_0) { '22641409810006421' }
  let(:field_876_subfield_r) { 'false' }
  let(:field_876_subfield_s) { 'IPLCBrill' }
  let(:fields) do
    [
      { '852' => { 'subfields' => [{ 'c' => field_852_subfield_c, '8' => field_852_subfield_8 }] } },
      { '876' => { 'subfields' => [{ 'a' => field_876_subfield_a, '0' => field_876_subfield_0, 'r' => field_876_subfield_r, 's' => field_876_subfield_s }] } }
    ]
  end
  let(:leader) { +'00426dad a2200133 i 4500' }
  let(:record) { described_class.new(MARC::Record.new_from_hash('fields' => fields, 'leader' => leader)) }
  describe('#valid?') do
    context 'when the record has everything it needs' do
      it 'returns true' do
        expect(record.valid?).to eq(true)
      end
    end
    context 'when the record has a 3-letter scsb location in 852$c' do
      let(:field_852_subfield_c) { 'xmr' }
      it 'returns true' do
        expect(record.valid?).to eq(true)
      end
    end
    context 'when the record has no valid alma 852$8' do
      let(:field_852_subfield_8) { '12345' }
      it 'returns false' do
        expect(record.valid?).to eq(false)
      end
    end
    context 'when the record has no valid scsb location in 852$c' do
      let(:field_852_subfield_c) { 'bad' }
      it 'returns false' do
        expect(record.valid?).to eq(false)
      end
    end
    context 'when the record has no valid alma 876$a' do
      let(:field_876_subfield_a) { '67890' }
      it 'returns false' do
        expect(record.valid?).to eq(false)
      end
    end
    context 'when the record has no valid alma 876$0' do
      let(:field_876_subfield_0) { '13579' }
      it 'returns false' do
        expect(record.valid?).to eq(false)
      end
    end
  end

  describe('#cgd') do
    context 'returns a Committed cgd' do
      let(:field_876_subfield_r) { 'true' }
      let(:field_852_subfield_c) { 'pl' }
      it 'returns Committed' do
        expect(record.cgd_assignment).to eq('Committed')
      end
    end
    context 'returns a Shared cgd' do
      let(:field_852_subfield_c) { 'pa' }
      it 'returns Shared' do
        expect(record.cgd_assignment).to eq('Shared')
      end
    end
    context 'returns a Private cgd' do
      let(:field_852_subfield_c) { 'pl' }
      it 'returns Private' do
        expect(record.cgd_assignment).to eq('Private')
      end
    end
  end
  describe('#recap_item_info') do
    context 'when location equals pa' do
      let(:field_852_subfield_c) { 'pa' }
      describe('customer_code key') do
        it 'returns PA' do
          expect(record.recap_item_info[:customer_code]).to eq('PA')
        end
      end
      describe('use_restriction key') do
        it 'returns nil' do
          expect(record.recap_item_info[:use_restriction]).to eq(nil)
        end
      end
    end
    context 'when location equals xmr' do
      let(:field_852_subfield_c) { 'xmr' }
      describe('customer_code key') do
        it 'returns PG' do
          expect(record.recap_item_info[:customer_code]).to eq('PG')
        end
      end
      describe('use_restriction key') do
        it 'returns Supervised Use' do
          expect(record.recap_item_info[:use_restriction]).to eq('Supervised Use')
        end
      end
    end
  end

  describe('#fixed record') do
    let(:fields) do
      [
        { '001' => '12345' },
        { 'a24' => { 'subfields' => [{ 'a' => 'nah' }] } },
        { '902' => { 'subfields' => [{ 'a' => 'anything' }] } }
      ]
    end

    it('is fixed using the record_fixes method') do
      fixed_record = record.record_fixes
      expect(fixed_record['a24']).to be nil
      expect(fixed_record['902']).to be nil
      expect(fixed_record['852']).to be nil
      expect(fixed_record.leader[5]).to eq('c')
    end
  end

  context 'when record is a host record' do
    let(:constituent_ids) { ["9933584373506421", "997007993506421", "997008003506421"] }
    let(:host_file) { Pathname.new(file_fixture_path).join("alma", 'host_record.xml').to_s }
    let(:host_record) { described_class.new(MARC::XMLReader.new(host_file).first) }

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
  end
end
