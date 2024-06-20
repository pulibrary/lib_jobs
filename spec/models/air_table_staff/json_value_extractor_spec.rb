# frozen_string_literal: true
require 'rails_helper'

RSpec.describe AirTableStaff::JsonValueExtractor do
  context 'when there is no transformer lambda provided in field config' do
    it 'extracts the text verbatim' do
      json = { cat: 'tabby cat' }
      field = { airtable_field: :cat }
      expect(described_class.new(json:, field:).extract).to eq('tabby cat')
    end
  end
  context 'when there is a transformer lambda provided in field config' do
    it 'extracts the text verbatim' do
      json = { cat: 'tabby cat' }
      field = { airtable_field: :cat, transformer: ->(value) { "My favorite cat is #{value}" } }
      expect(described_class.new(json:, field:).extract).to eq('My favorite cat is tabby cat')
    end
  end
end
