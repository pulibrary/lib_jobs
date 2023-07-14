# frozen_string_literal: true
require 'rails_helper'

RSpec.describe(AlmaSubmitCollection::MarcRecord) do
  let(:field_852_subfield_c) { 'pa' }
  let(:field_852_subfield_8) { '22922994580006421' }
  let(:field_876_subfield_a) { '23579686040006421' }
  let(:field_876_subfield_0) { '22641409810006421' }
  let(:fields) do
    [
      { '852' => { 'subfields' => [{ 'c' => field_852_subfield_c, '8' => field_852_subfield_8 }] } },
      { '876' => { 'subfields' => [{ 'a' => field_876_subfield_a, '0' => field_876_subfield_0 }] } }
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
end
