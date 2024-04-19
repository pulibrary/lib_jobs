# frozen_string_literal: true
require 'rails_helper'

RSpec.describe AlmaSubmitCollection::AlmaRecapFileList, type: :model do
  include_context 'sftp'
  subject(:alma_recap_file_list) { described_class.new }

  let(:alma_recap_filename) { 'incremental_recap_25908087650006421_20230420_160408[057]_new.xml.tar.gz' }
  let(:file_name) { instance_double("Net::SFTP::Protocol::V01::Name", name: alma_recap_filename) }
  let(:file_attributes) { instance_double("Net::SFTP::Protocol::V01::Attributes") }
  let(:sftp_file_factory) { Net::SFTP::Operations::FileFactory.new(sftp_session) }
  let(:file_size) { 1028 }

  before do
    allow(file_attributes).to receive(:size).and_return file_size
    allow(file_name).to receive(:attributes).and_return file_attributes
    allow(sftp_dir).to receive(:foreach).and_yield file_name
    allow(sftp_session).to receive(:file).and_return sftp_file_factory
    allow(sftp_session).to receive(:rename)
    allow(sftp_file_factory).to receive(:open).and_return StringIO.new
  end

  context 'metering files sent to recap' do
    before do
      allow(Flipflop).to receive(:meter_files_sent_to_recap?).and_return(true)
    end

    context 'with more files than recap can process' do
      let(:sftp_entry1) { instance_double("Net::SFTP::Protocol::V01::Name", name: 'incremental_recap_25908087650006421_20230420_160408[001]_new.xml.tar.gz') }
      let(:sftp_entry2) { instance_double("Net::SFTP::Protocol::V01::Name", name: 'incremental_recap_25908087650006421_20230420_160408[002]_new.xml.tar.gz') }
      let(:sftp_entry3) { instance_double("Net::SFTP::Protocol::V01::Name", name: 'incremental_recap_25908087650006421_20230420_160408[003]_new.xml.tar.gz') }
      let(:sftp_entry4) { instance_double("Net::SFTP::Protocol::V01::Name", name: 'incremental_recap_25908087650006421_20230420_160408[004]_new.xml.tar.gz') }
      let(:sftp_entry5) { instance_double("Net::SFTP::Protocol::V01::Name", name: 'incremental_recap_25908087650006421_20230420_160408[005]_new.xml.tar.gz') }
      # Ages are in seconds from epoch
      let(:age_1_oldest) { 1_713_400_100 }
      let(:age_2) { 1_713_400_200 }
      let(:age_3) { 1_713_400_300 }
      let(:age_4) { 1_713_400_400 }
      let(:age_5_newest) { 1_713_400_500 }

      before do
        allow(sftp_dir).to receive(:foreach).and_yield(sftp_entry1).and_yield(sftp_entry2)
                                            .and_yield(sftp_entry3).and_yield(sftp_entry4).and_yield(sftp_entry5)
        [sftp_entry1, sftp_entry2, sftp_entry3, sftp_entry4, sftp_entry5].each do |entry|
          allow(entry).to receive(:attributes).and_return(file_attributes)
        end
        allow(sftp_dir).to receive(:glob).and_return [sftp_entry1, sftp_entry2, sftp_entry3, sftp_entry4, sftp_entry5]
        allow(file_attributes).to receive(:mtime).and_return(age_1_oldest, age_5_newest, age_2, age_4, age_3)
      end
      it 'does not process more than the configured number of files' do
        expect(alma_recap_file_list.files.count).to eq(3)
      end

      it 'processes only the oldest files' do
        expect(alma_recap_file_list.files).to match_array([sftp_entry1.name, sftp_entry3.name, sftp_entry5.name])
      end
    end
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
      expect(decompressed_file_contents.first.read).to include(title_field)
    end
  end
  describe '#mark_files_as_processed' do
    before do
      allow(sftp_file_factory).to receive(:open).and_return File.new(Pathname.new(file_fixture_path).join("alma", alma_recap_filename))
    end
    it 'renames the file to .processed' do
      old_filepath = "/alma/recap/incremental_recap_25908087650006421_20230420_160408[057]_new.xml.tar.gz"
      new_filepath = "/alma/recap/incremental_recap_25908087650006421_20230420_160408[057]_new.xml.tar.gz.processed"
      alma_recap_file_list.mark_files_as_processed
      expect(sftp_session).to have_received(:rename).with(old_filepath, new_filepath)
    end
  end
end
