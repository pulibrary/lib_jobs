# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Tarball, type: :model do
  it 'can untar a .tar.gz file' do
    file = File.new file_fixture('pod.tar.gz')
    records = Nokogiri::XML(described_class.new(file).contents.first)
    title = 'Lectures on differential topology /'
    expect(records.xpath('//datafield[@tag="245"]/subfield[@code="a"]/text()').first.to_s).to eq(title)
  end
end
