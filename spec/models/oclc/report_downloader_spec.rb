# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Oclc::ReportDownloader, type: :model do
  context "OCLC exception report downloader" do
    subject(:exception_report_downloader) do
      described_class.new(file_pattern: 'BibExceptionReport.txt$', process_class: Oclc::DataSyncExceptionFile, input_sftp_base_dir: '/xfer/metacoll/reports/', recent: true)
    end
    it 'can be instantiated' do
      expect(exception_report_downloader).to be
    end
    it 'knows what directory to look in' do
      expect(exception_report_downloader.input_sftp_base_dir).to eq('/xfer/metacoll/reports/')
    end

    it 'knows what file pattern to look for' do
      expect(exception_report_downloader.file_pattern).to eq('BibExceptionReport.txt$')
    end

    it 'knows what process class to use' do
      expect(exception_report_downloader.process_class).to eq(Oclc::DataSyncExceptionFile)
    end

    it 'can connect to OCLC sftp' do
      expect(exception_report_downloader.oclc_sftp).to be_instance_of(OclcSftp)
    end
  end
end
