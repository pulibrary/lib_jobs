# frozen_string_literal: true
require 'rails_helper'

RSpec.describe(AlmaSubmitCollection::MarcS3Writer) do
  Aws.config[:stub_responses] = true
  let(:s3_credentials) { instance_double("Aws::Credentials") }
  let(:s3_client) { Aws::S3::Client.new(region: 'region-1', credentials: s3_credentials) }
  context 'when we attempt to write more files than the records_per_file limit' do
    it 'opens a new file' do
      files_sent_to_s3 = []
      s3_client.stub_responses(
        :put_object, lambda { |context|
          files_sent_to_s3 << Zlib::GzipReader.new(context.params[:body])
        }
      )
      writer = described_class.new(records_per_file: 5)
      allow(writer).to receive(:done)
      7.times { writer.write(MARC::Record.new_from_hash({ 'leader' => '00426dad a2200133 i 4500', 'fields' => [{ '001' => '1234' }] })) }
      # allow(s3_client).to receive(:put_object).with(bucket: 'test', key: 'data-feed/submitcollections/PUL/cgd_protection/scsb_abc_123', body: files_sent_to_s3).and_return(files_sent_to_s3)
      writer.done
      expect(files_sent_to_s3.length).to eq 2
      expect(MARC::XMLReader.new(files_sent_to_s3.first).to_a.length).to eq(5)
      expect(MARC::XMLReader.new(files_sent_to_s3.second).to_a.length).to eq(2)
    end
  end
end
