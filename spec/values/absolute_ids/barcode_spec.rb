# frozen_string_literal: true
require 'rails_helper'

RSpec.describe AbsoluteIds::Barcode do
  subject(:barcode) { described_class.new(value) }
  let(:value) { '0000000000001' }

  describe '#+' do
    it 'increments the barcode' do
      expect(barcode.value).to eq('0000000000001')

      incremented = barcode + 1
      expect(incremented).to be_a(described_class)
      expect(incremented.value).to eq('0000000000002')
      expect(barcode.value).to eq('0000000000002')
    end
  end

  describe '#valid?' do
    let(:invalid_barcode) { described_class.new('1234') }
    xit 'determines whether or not the barcode is valid' do
      expect(barcode.valid?).to be true

      expect(invalid_barcode.valid?).to be false
    end

    it 'defaults to false' do
      expect(barcode.valid?).to be false
    end
  end

  describe '.generate_check_digit' do
    let(:code) { value }

    xit 'generates valid check digit for any code' do
      expect(described_class.generate_check_digit(code)).to eq(9)
      expect(described_class.generate_check_digit('0000000000002')).to eq(8)
    end

    it 'generates the check digit for the code' do
      expect(described_class.generate_check_digit(code)).to eq(9)
    end
  end
end
