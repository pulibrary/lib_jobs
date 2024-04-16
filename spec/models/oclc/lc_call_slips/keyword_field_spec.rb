# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Oclc::LcCallSlips::KeywordField do
  shared_examples 'a match' do
    it 'match? returns true' do
      expect(described_class.new(field:, keywords:).match?).to eq(true)
    end
  end
  shared_examples 'not a match' do
    it 'match? returns false' do
      expect(described_class.new(field:, keywords:).match?).to eq(false)
    end
  end
  context 'when field is a control field' do
    let(:field) { MARC::ControlField.new('001', 'SCSB-10482146') }
    let(:keywords) { ['cantaloup*'] }
    it_behaves_like 'not a match'
  end

  context 'when field is a 100' do
    let(:field) do
      MARC::DataField.new('100', '1', '',
            MARC::Subfield.new('a', 'Westbrook, Catherine'))
    end
    let(:keywords) { ['Westbrook'] }
    it_behaves_like 'a match'
  end

  context 'when field is a 245' do
    let(:field) do
      MARC::DataField.new('245', '0', '0',
            MARC::Subfield.new('a', 'Cantaloups'))
    end
    let(:keywords) { ['cantaloup*'] }
    it_behaves_like 'a match'
  end

  context 'when field is a 246' do
    let(:field) do
      MARC::DataField.new('246', '0', '0',
            MARC::Subfield.new('a', 'Cantaloupe culture'))
    end
    let(:keywords) { ['cantaloup*'] }
    it_behaves_like 'a match'
  end

  context 'when field is a 260' do
    let(:field) do
      MARC::DataField.new('260', '0', '0',
            MARC::Subfield.new('b', 'The Rocky Ford Cantaloupe Seed Breeders\' Association'))
    end
    let(:keywords) { ['cantaloup*'] }
    it_behaves_like 'a match'
    context 'when keyword includes multiple wildcards' do
      let(:keywords) { ['*nt*loup*'] }
      it_behaves_like 'a match'
    end
    context 'when the first matching keyword comes late in the array' do
      let(:keywords) { ['sediment', 'metamorphosis', 'geolog*', 'igneous', 'rock*', 'sandstone'] }
      it_behaves_like 'a match'
    end
  end

  context 'when field is a 300' do
    let(:field) do
      MARC::DataField.new('300', '0', '0',
            MARC::Subfield.new('a', '1 online resource (2 pages), digital, PDF file'))
    end
    let(:keywords) { ['online'] }
    it_behaves_like 'not a match'
  end
end
