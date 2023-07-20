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
  let(:leader) { '00426dad a2200133 i 4500' }
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
end
