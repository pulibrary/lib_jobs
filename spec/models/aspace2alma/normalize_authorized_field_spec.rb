# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Aspace2alma::NormalizeAuthorizedField do
  it 'normalizes a 100 field with lcnaf appropriately' do
    original = <<~END_ORIGINAL
      <record xmlns="http://www.loc.gov/MARC21/slim" xmlns:marc="http://www.loc.gov/MARC21/slim" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.loc.gov/MARC21/slim http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd">
        <datafield tag="100" ind1="1" ind2=" "><subfield code="a">Rogers, Morgan</subfield><subfield code="q">(Morgan A.)</subfield><subfield code="2">lcnaf</subfield></datafield>
      </record>
    END_ORIGINAL
    datafield = Nokogiri.parse(original).xpath('//marc:datafield').first

    normalized = described_class.new.call(datafield)
    expect(normalized['tag']).to eq '100'
    expect(normalized['ind1']).to eq '1'
    expect(normalized['ind2']).to eq ' '
    expect(normalized.to_s).to include 'Rogers, Morgan'
    expect(normalized.to_s).to include '(Morgan A.)'
    expect(normalized.to_s).not_to include 'lcnaf'
  end

  it 'can handle an id with XML entities in it' do
    original = <<~END_ORIGINAL
      <record xmlns="http://www.loc.gov/MARC21/slim" xmlns:marc="http://www.loc.gov/MARC21/slim" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.loc.gov/MARC21/slim http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd">
        <datafield tag="100" ind1="1" ind2=" "><subfield code="a">Rogers, Morgan</subfield><subfield code="q">(Morgan A.)</subfield><subfield code="0">http://example.org/names?id=123&amp;lang=en</subfield></datafield>
      </record>
    END_ORIGINAL
    datafield = Nokogiri.parse(original).xpath('//marc:datafield').first

    normalized = described_class.new.call(datafield)
    expect(normalized.element_children.select { |subfield| subfield['code'] == '0' }.map(&:content))
      .to eq ['http://example.org/names?id=123&lang=en']
  end
end
