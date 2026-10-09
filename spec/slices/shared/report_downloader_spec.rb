# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Shared::ReportDownloader, :file_download, type: :model do
  context 'OCLC exception report downloader' do
    subject(:downloader) do
      described_class.new
    end

    it 'can be instantiated' do
      expect(downloader).to be_truthy
    end

    context 'running the downloader' do
      subject(:downloader) do
        described_class.new
      end

      include_context 'sftp'

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
      let(:sftp_entry1) { instance_double(Net::SFTP::Protocol::V01::Name, name: file_name_to_download_one) }
      let(:sftp_entry2) { instance_double(Net::SFTP::Protocol::V01::Name, name: file_name_to_download_two) }
      let(:sftp_entry3) { instance_double(Net::SFTP::Protocol::V01::Name, name: file_name_to_skip_one) }
      let(:sftp_entry4) { instance_double(Net::SFTP::Protocol::V01::Name, name: file_name_to_skip_two) }
      let(:sftp_entry5) { instance_double(Net::SFTP::Protocol::V01::Name, name: file_name_to_skip_three) }
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
        downloader.run(described_class::Context[file_pattern: 'BibExceptionReport.txt', process_class: Oclc::DataSyncExceptionFile, input_sftp_base_dir: '/xfer/metacoll/reports/', recent: true])
        expect(sftp_session).to have_received(:download!).with(file_full_path_one, temp_file_one)
        expect(sftp_session).to have_received(:download!).with(file_full_path_two, temp_file_two)
      end

      it 'logs a warning and does not raise an error if we cannot find a date in the filename using our pattern' do
        allow(Rails.logger).to receive(:warn)
        expect do
          downloader.run(described_class::Context[date_file_pattern: /I DO NOT MATCH ANY FILE/, file_pattern: 'BibExceptionReport.txt', process_class: Oclc::DataSyncExceptionFile,
                                                  input_sftp_base_dir: '/xfer/metacoll/reports/', recent: true])
        end.not_to raise_error
        expect(Rails.logger).to have_received(:warn).with(/Tried to find date in file/).exactly(3).times
      end
    end
  end
end
