# frozen_string_literal: true
require 'rails_helper'

RSpec.describe ReportDownloader, type: :model do
  context "OCLC exception report downloader" do
    subject(:downloader) do
      described_class.new(file_pattern: 'BibExceptionReport.txt$', process_class: Oclc::DataSyncExceptionFile, input_sftp_base_dir: '/xfer/metacoll/reports/', recent: true)
    end
    it 'can be instantiated' do
      expect(downloader).to be
    end
    it 'knows what directory to look in' do
      expect(downloader.input_sftp_base_dir).to eq('/xfer/metacoll/reports/')
    end

    it 'knows what file pattern to look for' do
      expect(downloader.file_pattern).to eq('BibExceptionReport.txt$')
    end

    it 'knows what process class to use' do
      expect(downloader.process_class).to eq(Oclc::DataSyncExceptionFile)
    end

    it 'can connect to OCLC sftp' do
      expect(downloader.sftp).to be_instance_of(OclcSftp)
    end

    it 'logs a warning and does not raise an error if there is no date' do
      allow(Rails.logger).to receive(:warn)
      expect { downloader.date_in_range?(file_name: 'something') }.not_to raise_error
      expect(Rails.logger).to have_received(:warn).once.with("Tried to find date in file: something using matching pattern: .IN.BIB.D(\\d{8}) and did not find a date")
    end

    context 'running the downloader' do
      include_context 'sftp'
      subject(:downloader) do
        described_class.new(file_pattern: 'BibExceptionReport.txt', process_class: Oclc::DataSyncExceptionFile, input_sftp_base_dir: '/xfer/metacoll/reports/', recent: true)
      end
      let(:input_sftp_base_dir) { Rails.application.config.oclc_sftp.data_sync_report_path }
      let(:file_full_path_one) { "#{input_sftp_base_dir}#{file_name_to_download_one}" }
      let(:file_full_path_two) { "#{input_sftp_base_dir}#{file_name_to_download_two}" }
      let(:temp_file_one) { Tempfile.new(encoding: 'ascii-8bit') }
      let(:temp_file_two) { Tempfile.new(encoding: 'ascii-8bit') }
      let(:file_name_to_download_one) { 'PUL-PUL.1012676.IN.BIB.D20230712.T115712289.1012676.pul.non-pcc_27837389230006421_new.mrc_2.BibExceptionReport.txt' }
      let(:file_name_to_download_two) { 'PUL-PUL.1012676.IN.BIB.D20230712.T115732756.1012676.pul.non-pcc_27837389230006421_new.mrc_1.BibExceptionReport.txt' }
      # too old
      let(:file_name_to_skip_one) { 'PUL-PUL.1012676.IN.BIB.D20230526.T144121659.1012676.pul.non-pcc_26337509860006421_new.mrc_1.BibExceptionReport.txt' }
      # different type of report
      let(:file_name_to_skip_two) { 'PUL-PUL.1012676.IN.BIB.D20230712.T115712289.1012676.pul.non-pcc_27837389230006421_new.mrc_2.LbdExceptionReport.txt' }
      # already processed
      let(:file_name_to_skip_three) { 'PUL-PUL.1012676.IN.BIB.D20230712.T115712289.1012676.pul.non-pcc_27837389230006421_new.mrc_2.BibExceptionReport.txt.processed' }
      let(:sftp_entry1) { instance_double("Net::SFTP::Protocol::V01::Name", name: file_name_to_download_one) }
      let(:sftp_entry2) { instance_double("Net::SFTP::Protocol::V01::Name", name: file_name_to_download_two) }
      let(:sftp_entry3) { instance_double("Net::SFTP::Protocol::V01::Name", name: file_name_to_skip_one) }
      let(:sftp_entry4) { instance_double("Net::SFTP::Protocol::V01::Name", name: file_name_to_skip_two) }
      let(:sftp_entry5) { instance_double("Net::SFTP::Protocol::V01::Name", name: file_name_to_skip_three) }
      let(:freeze_time) { Time.utc(2023, 7, 13, 10, 30, 5, 835_000) }
      before do
        allow(Tempfile).to receive(:new).and_return(temp_file_one, temp_file_two)
        allow(sftp_dir).to receive(:foreach).and_yield(sftp_entry1).and_yield(sftp_entry2)
                                            .and_yield(sftp_entry3).and_yield(sftp_entry4).and_yield(sftp_entry5)
        allow(sftp_session).to receive(:download!).with(file_full_path_one, temp_file_one)
        allow(sftp_session).to receive(:download!).with(file_full_path_two, temp_file_two)
      end
      around do |example|
        Timecop.freeze(freeze_time) do
          example.run
        end
      end
      it 'downloads the correct files' do
        downloader.run
        expect(sftp_session).to have_received(:download!).with(file_full_path_one, temp_file_one)
        expect(sftp_session).to have_received(:download!).with(file_full_path_two, temp_file_two)
      end
    end
  end
end
