# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Aspace2alma::MarcRules do
  describe '.authority_subfield' do
    {
      ['https://viaf.org/viaf/70595093', 'viaf'] => ['1', 'http://viaf.org/viaf/70595093'],
      ['http://www.viaf.org/viaf/70595093/', 'lcnaf'] => ['1', 'http://viaf.org/viaf/70595093'],
      ['https://viaf.org/en/viaf/70595093', nil] => ['1', 'http://viaf.org/viaf/70595093'],
      ['(viaf)70595093', 'local'] => ['1', 'http://viaf.org/viaf/70595093'],
      ['70595093', 'viaf'] => ['1', 'http://viaf.org/viaf/70595093'],
      ['http://id.loc.gov/authorities/names/n79021164', 'lcnaf'] => ['0', 'http://id.loc.gov/authorities/names/n79021164'],
      ['70595093', 'lcnaf'] => nil,
      ['MOOREHUGH70595093.', 'viaf'] => nil,
      ['(DLC)n79021164', 'lcnaf'] => nil,
      ['https://viaf.org/viaf/search?query=moore', 'viaf'] => nil,
      ['', 'viaf'] => nil
    }.each do |(identifier, source), subfield|
      it "maps #{identifier.inspect} from #{source.inspect} to #{subfield.inspect}" do
        expect(described_class.authority_subfield(identifier, source)).to eq(subfield)
      end
    end
  end

  describe '.lc_source?' do
    it 'is true for LC and VIAF sources' do
      expect(%w[lcnaf lcsh viaf].map { |source| described_class.lc_source?(source) }).to all(be(true))
    end

    it 'is false for other sources' do
      expect(['local', 'aat', nil].map { |source| described_class.lc_source?(source) }).to all(be(false))
    end
  end
end
