# frozen_string_literal: true
require 'rails_helper'

RSpec.describe AlmaSubmitCollection::AlmaRecapFileList, type: :model do
  subject(:alma_recap_file_list) { described_class.new }

  let(:alma_recap_filename) { 'incremental_recap_25908087650006421_20230420_160408[057]_new.xml.tar.gz' }
  let(:file_name) { instance_double("Net::SFTP::Protocol::V01::Name", name: alma_recap_filename) }
  let(:file_attributes) { instance_double("Net::SFTP::Protocol::V01::Attributes") }
  let(:sftp_session) { instance_double("Net::SFTP::Session", dir: sftp_dir) }
  let(:sftp_dir) { instance_double("Net::SFTP::Operations::Dir") }
  let(:sftp_file_factory) { Net::SFTP::Operations::FileFactory.new(sftp_session) }
  let(:file_size) { 1028 }

  before do
    allow(file_attributes).to receive(:size).and_return file_size
    allow(file_name).to receive(:attributes).and_return file_attributes
    allow(sftp_dir).to receive(:foreach).and_yield file_name
    allow(sftp_session).to receive(:file).and_return sftp_file_factory
    allow(sftp_session).to receive(:rename)
    allow(sftp_file_factory).to receive(:open).and_return StringIO.new
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
    before do
      allow(sftp_file_factory).to receive(:open).and_return File.new(Pathname.new(file_fixture_path).join("alma", alma_recap_filename))
    end
    it 'downloads and returns the content of the file' do
      title_field = '<datafield tag="245" ind1="1" ind2="0"><subfield code="a">Distress in the fields :</subfield>'\
                    '<subfield code="b">Indian agriculture after liberalization /</subfield>'\
                    '<subfield code="c">edited by R. Ramakumar.</subfield></datafield>'
      decompressed_file_contents = alma_recap_file_list.download_and_decompress_file(alma_recap_filename)
      expect(decompressed_file_contents.first.string).to include(title_field)
    end
    it 'renames the file to .processed' do
      old_filepath = "/alma/recap/incremental_recap_25908087650006421_20230420_160408[057]_new.xml.tar.gz"
      new_filepath = "/alma/recap/incremental_recap_25908087650006421_20230420_160408[057]_new.xml.tar.gz.processed"
      alma_recap_file_list.download_and_decompress_file(alma_recap_filename)
      expect(sftp_session).to have_received(:rename).with(old_filepath, new_filepath)
    end
  end
end
