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
    context 'when 876$r is the string "true" and we have a valid retention reason' do
      let(:field_876_subfield_r) { 'true' }
      let(:field_852_subfield_c) { 'pl' }
      it 'puts Committed in 876$x (cgd) field' do
        expect(record.version_for_recap['876']['x']).to eq('Committed')
      end
    end
    context 'when 852$c is a shared location' do
      let(:field_852_subfield_c) { 'pa' }
      it 'puts Shared in 876$x (cgd) field' do
        expect(record.version_for_recap['876']['x']).to eq('Shared')
      end
    end
    context 'when 852$c is a private location' do
      let(:field_852_subfield_c) { 'pl' }
      it 'puts Private in 876$x (cgd) field' do
        expect(record.version_for_recap['876']['x']).to eq('Private')
      end
    end
  end
  describe('#recap_item_info') do
    context 'when location equals pa' do
      let(:field_852_subfield_c) { 'pa' }
      describe('876$z') do
        it 'returns PA' do
          expect(record.version_for_recap['876']['z']).to eq('PA')
        end
      end
      describe('876$h') do
        it 'returns an empty string' do
          expect(record.version_for_recap['876']['h']).to eq('')
        end
      end
    end
    context 'when location equals xmr' do
      let(:field_852_subfield_c) { 'xmr' }
      describe('876$z') do
        it 'returns PG' do
          expect(record.version_for_recap['876']['z']).to eq('PG')
        end
      end
      describe('876$h') do
        it 'returns Supervised Use' do
          expect(record.version_for_recap['876']['h']).to eq('Supervised Use')
        end
      end
    end
  end

  describe('#record_fixes') do
    let(:fields) do
      [
        { '001' => +'12345' },
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
