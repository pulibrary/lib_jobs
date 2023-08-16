# frozen_string_literal: true
require 'rails_helper'

RSpec.describe(AlmaSubmitCollection::MarcS3Writer) do
  let(:s3_client) { Aws::S3::Client.new(stub_responses: true) }
  context 'when we attempt to write more files than the records_per_file limit' do
    it 'opens a new file' do
      allow_any_instance_of(AlmaSubmitCollection::PartnerS3).to receive(:s3_client_connection).and_return(s3_client)
      files_sent_to_s3 = []
      s3_client.stub_responses(
        :put_object, lambda { |context|
          files_sent_to_s3 << Zlib::GzipReader.new(StringIO.new(context.params[:body]))
        }
      )

      writer = described_class.new(records_per_file: 5)
      7.times { writer.write(MARC::Record.new_from_hash({ 'leader' => '00426dad a2200133 i 4500', 'fields' => [{ '001' => '1234' }] })) }
      writer.done
      expect(files_sent_to_s3.length).to eq 2
      expect(MARC::XMLReader.new(files_sent_to_s3.first).to_a.length).to eq(5)
      expect(MARC::XMLReader.new(files_sent_to_s3.second).to_a.length).to eq(2)
    end
  end
end
