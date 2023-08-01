# frozen_string_literal: true
require 'rails_helper'

RSpec.describe(AlmaSubmitCollection::MarcS3Writer) do
  context 'when we attempt to write more files than the records_per_file limit' do
    it 'opens a new file' do
      writer = described_class.new(records_per_file: 5, s3_client: Aws::S3::Client.new(stub_responses: true))
      7.times { writer.write(MARC::Record.new_from_hash({ 'leader' => '00426dad a2200133 i 4500', 'fields' => [{ '001' => '1234' }] })) }
      writer.done
      expect(writer.filenames_on_disk.length).to eq(2)
      expect(MARC::XMLReader.new(writer.filenames_on_disk.first).to_a.length).to eq(5)
      expect(MARC::XMLReader.new(writer.filenames_on_disk.second).to_a.length).to eq(2)
    end
  end
end
