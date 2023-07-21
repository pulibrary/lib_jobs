# frozen_string_literal: true
require 'rails_helper'

RSpec.describe(AlmaSubmitCollection::MarcLocationFieldFactory) do
  it 'produces a location in the format branch$location' do
    original_field = MARC::DataField.new('852', '8', ' ')
    original_field.append(MARC::Subfield.new('b', 'firestone'))
    original_field.append(MARC::Subfield.new('c', 'pf'))
    original_field.append(MARC::Subfield.new('h', 'MICROFILM S01063 reel 58-65'))
    original_field.append(MARC::Subfield.new('8', '22641409810006421'))
    factory = described_class.new(original_field)
    expect(factory.generate['b']).to eq('firestone$pf')
  end
end
