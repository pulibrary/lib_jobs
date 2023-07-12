# frozen_string_literal: true
require 'rails_helper'

RSpec.describe AlmaSubmitCollection::AlmaRecapFileList, type: :model do
  subject(:alma_recap_file_list) { described_class.new }

  let(:alma_recap_filename) { 'incremental_recap_25908087650006421_20230420_160408[057]_new.xml.tar.gz' }
  let(:file_name) { instance_double("Net::SFTP::Protocol::V01::Name", name: alma_recap_filename) }
  let(:file_attributes) { instance_double("Net::SFTP::Protocol::V01::Attributes") }
  let(:sftp_session) { instance_double("Net::SFTP::Session", dir: sftp_dir) }
  let(:sftp_dir) { instance_double("Net::SFTP::Operations::Dir") }
  let(:file_size) { 1028 }

  before do
    allow(file_attributes).to receive(:size).and_return file_size
    allow(file_name).to receive(:attributes).and_return file_attributes
    allow(sftp_dir).to receive(:foreach).and_yield file_name
    allow(sftp_session).to receive(:file).and_return StringIO
    allow(Net::SFTP).to receive(:start).and_yield sftp_session
  end

  context 'if the file is valid' do
    it "downloads the file" do
      expect(alma_recap_file_list.files.count).to eq(1)
    end
  end

  context "if the filename doesn't match the pattern" do
    let(:alma_recap_filename) { 'BAD' }
    it "doesn't download the file" do
      expect(alma_recap_file_list.files).to be_empty
    end
  end

  context 'if the file is empty' do
    let(:file_size) { 0 }
    it "doesn't download the file" do
      expect(alma_recap_file_list.files).to be_empty
    end
  end

  describe '#download_and_decompress_file' do
    pending 'we need to decompress the fixture file before checking, also get a smaller file'
    it 'downloads and returns the content of the file' do
      results = alma_recap_file_list.download_and_decompress_file(alma_recap_filename)
      expect(results.first.readlines).to eq(File.new(Pathname.new(file_fixture_path).join("alma", alma_recap_filename)).readlines)
    end
  end
end
