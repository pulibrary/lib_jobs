# frozen_string_literal: true
require 'rails_helper'

RSpec.describe AlmaSubmitCollection::MarcFileProcessor, type: :model do
  let(:filename) { 'host_record.xml' }
  let(:files_sent_to_s3) { [] }
  let(:s3_partner) { instance_double(AlmaSubmitCollection::PartnerS3) }
  let(:s3_client) { Aws::S3::Client.new(stub_responses: true) }
  let(:processor) { described_class.new(file: File.new(Pathname.new(file_fixture_path).join("alma", filename)), s3_partner:) }
  let(:constituent_ids) { ["9933584373506421", "997007993506421", "997008003506421"] }

  before do
    stub_alma_bibs(ids: constituent_ids, status: 200, fixture: "constituent_records.xml", apikey: '1234')
    allow(s3_partner).to receive(:bucket_name).and_return('test-bucket')
    allow(s3_partner).to receive(:client).and_return(s3_client)
  end
  context "when the file has valid MARC records" do
    it 'processed all valid records in a file' do
      processor.process
      expect(processor.records_processed).to eq(8)
    end
  end
  context "when the file has invalid MARC records" do
    let(:filename) { 'record_without_852.xml' }
    it 'does not process the invalid records' do
      processor.process
      expect(processor.records_processed).to eq(0)
    end
  end

  describe "#constituent_record_file" do
    let(:constituent_ids) { ["9933584373506421", "997007993506421", "997008003506421"] }
    before do
      stub_alma_bibs(ids: constituent_ids, status: 200, fixture: "constituent_records.xml", apikey: '1234')
      s3_client.stub_responses(
        :put_object, lambda { |context|
          files_sent_to_s3 << Zlib::GzipReader.new(StringIO.new(context.params[:body]))
        }
      )
    end
    it 'contains host records from the file from lib-sftp' do
      processor.process
      @reader = MARC::XMLReader.new(files_sent_to_s3.first)
      host = @reader.first
      expect(host['245']['a']).to eq('Multi-title collection including Presse scientifiques des deux mondes and 2 others.')
    end
    it 'contains constituent records taken from the Alma API' do
      processor.process
      @reader = MARC::XMLReader.new(files_sent_to_s3.first)
      constituent = @reader.to_a.second
      expect(constituent['245']['a']).to eq('Presse scientifiques des deux mondes')
    end
    it 'contains 852 from host record' do
      processor.process
      @reader = MARC::XMLReader.new(files_sent_to_s3.first)
      constituent = @reader.to_a.third
      f852s = constituent.fields('852').select { |f852| f852['h'] == 'MICROFILM S01063 reel 58-65' }
      expect(f852s.length).to eq 1
    end
    it 'does not contain the 852 that was originally in the constituent record' do
      processor.process
      @reader = MARC::XMLReader.new(files_sent_to_s3.first)
      constituent = @reader.to_a.third
      f852s = constituent.fields('852').select { |f852| f852['h'] == 'Unwanted field' }
      expect(f852s).to be_empty
    end
    it 'contains 866$a from host record' do
      processor.process
      @reader = MARC::XMLReader.new(files_sent_to_s3.first)
      constituent = @reader.to_a.third
      f866s = constituent.fields('866').select { |f866| f866['a'] == '1. année, 1. t. no. 1 (16 juil. 1860)-(15 sept. 1867).' }
      expect(f866s.length).to eq 1
    end
    it 'contains 876$a (item ID) from host record' do
      processor.process
      @reader = MARC::XMLReader.new(files_sent_to_s3.first)
      constituent = @reader.to_a.third
      f876s = constituent.fields('876').select { |f876| f876['a'] == '23579686040006421' }
      expect(f876s.length).to eq 1
    end
  end
end
