# frozen_string_literal: true
require 'rails_helper'

RSpec.describe MarcCollection, type: :model do
  it 'adds namespaces' do
    document = File.new(file_fixture('marcxml_no_namespaces.xml'))
    io = StringIO.new
    described_class.new(document).write(io)
    expect(io.closed?).to eq true
    parsed_io = Nokogiri::XML(io.string)
    expect(parsed_io.xpath('//marc:collection', 'marc' => 'http://www.loc.gov/MARC21/slim').count).to eq(1)
  end
end
