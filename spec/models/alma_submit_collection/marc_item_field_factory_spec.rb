# frozen_string_literal: true
require 'rails_helper'

RSpec.describe(AlmaSubmitCollection::MarcItemFieldFactory) do
  let(:original_fields) do
    original_field = MARC::DataField.new('876', ' ', ' ')
    original_field.append(MARC::Subfield.new('0', '22641409810006421'))
    original_field.append(MARC::Subfield.new('a', '23579686040006421'))
    original_field.append(MARC::Subfield.new('j', '1'))
    original_field.append(MARC::Subfield.new('3', 'r. 58, v 1&amp; 2, Jul 16-Dec 16, 1860'))
    original_field.append(MARC::Subfield.new('d', '2016-12-12 19:00:00 US/Eastern'))
    original_field.append(MARC::Subfield.new('p', '32101053143440'))
    original_field.append(MARC::Subfield.new('t', '0'))
    [original_field]
  end
  let(:library) { 'firestone' }
  let(:location) { 'pf' }
  let(:factory) { described_class.new(original_fields:, library:, location:) }

  it 'includes 876$j Not Used' do
    expect(factory.generate['j']).to eq('Not Used')
  end
end
