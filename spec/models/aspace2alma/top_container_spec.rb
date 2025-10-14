# frozen_string_literal: false

require 'rails_helper'

RSpec.describe Aspace2alma::TopContainer do
  let(:container) { JSON.parse(File.read(file_fixture('aspace2alma/single_container.json'))) }
  let(:container_instance) { described_class.new(container) }
  let(:item_record_xml) do
    <<~XML
      <datafield ind1=' ' ind2=' ' tag='949'>
        <subfield code='a'>32101106176132</subfield>
        <subfield code='b'>volume 2477</subfield>
        <subfield code='c'>scarcpph</subfield>
        <subfield code='d'>(PULFA)MC001.01</subfield>
      </datafield>
    XML
  end
  it 'can be instantiated' do
    # expect(described_class.new(resource_uri, client, 'file', 'log_out', 'remote_file')).to be
    expect(described_class.new(container))
  end
  it 'has a container' do
    expect(container_instance.container_doc).to be_an_instance_of Hash
  end
  it 'has a location code' do
    expect(container_instance.location_code).to be_an_instance_of String
  end
  it 'has the correct location code' do
    expect(container_instance.location_code).to eq "scarcpph"
  end
  it 'is at ReCAP' do
    expect(container_instance.at_recap?).to be true
  end
  it 'has a barcode' do
    expect(container_instance.barcode).to be_truthy
  end
  it 'is a valid container' do
    expect(container_instance.valid?).to be true
  end

  it 'constructs a MARC item record' do
    expect(container_instance.item_record('MC001.01')).to eq item_record_xml
  end
end
