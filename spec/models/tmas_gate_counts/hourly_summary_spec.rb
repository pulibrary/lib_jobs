# frozen_string_literal: true
require 'rails_helper'

def entry_from_xml_string(string)
  Nokogiri::XML::DocumentFragment.parse(string).children.first
end

RSpec.describe TMASGateCounts::HourlySummary do
  it 'recognizes ARCH0000 as Architecture' do
    entry = entry_from_xml_string('<data storeId="ARCH0000" trafficDate="2026-04-01 16:00" trafficValue="25.0"/>')
    summary = described_class.from_entry(entry)
    expect(summary.location).to eq 'Architecture'
  end

  it 'recognizes PLLR0000 as East Asian' do
    entry = entry_from_xml_string('<data storeId="PLLR0000" trafficDate="2026-04-01 16:00" trafficValue="25.0"/>')
    summary = described_class.from_entry(entry)
    expect(summary.location).to eq 'East Asian Library'
  end

  it 'parses the float string into an integer' do
    entry = entry_from_xml_string('<data storeId="PLLR0000" trafficDate="2026-04-01 16:00" trafficValue="25.0"/>')
    summary = described_class.from_entry(entry)
    expect(summary.count).to eq 25
  end
end
