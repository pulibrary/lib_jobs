# frozen_string_literal: true
require 'rails_helper'

RSpec.describe AlmaPodRecords::AlmaPodJob, type: :model do
  it 'adds namespaces' do
    document = File.open(file_fixture('marcxml_no_namespaces.xml')) { |file| Nokogiri::XML(file) }
    list = AlmaPodRecords::AlmaPodFileList.new(documents: [document])
    job = described_class.new(incoming_file_list: list)
    expect(job.documents.first.xpath('//marc:collection', 'marc' => 'http://www.loc.gov/MARC21/slim').count).to eq(1)
  end
end
