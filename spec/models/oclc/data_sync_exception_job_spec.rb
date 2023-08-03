# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Oclc::DataSyncExceptionJob, type: :model do
  subject(:data_sync_exception_job) { described_class.new }
  it 'can be instantiated' do
    expect(data_sync_exception_job).to be
  end
  it 'knows what directory to look in' do
    expect(data_sync_exception_job.input_sftp_base_dir).to eq('/xfer/metacoll/reports/')
  end

  it 'knows what file pattern to look for' do
    expect(data_sync_exception_job.file_pattern).to eq('BibExceptionReport.txt$')
  end

  it 'can connect to OCLC sftp' do
    expect(data_sync_exception_job.oclc_sftp).to be_instance_of(OclcSftp)
  end

  context 'with files on the OCLC sftp server' do
    let(:input_sftp_base_dir) { Rails.application.config.oclc_sftp.data_sync_exception_path }
    let(:file_full_path_one) { "#{input_sftp_base_dir}#{file_name_to_download_one}" }
    let(:file_full_path_two) { "#{input_sftp_base_dir}#{file_name_to_download_two}" }
    let(:file_name_to_download_one) { 'PUL-PUL.1012676.IN.BIB.D20230712.T115712289.1012676.pul.non-pcc_27837389230006421_new.mrc_2.BibExceptionReport.txt' }
    let(:file_name_to_download_two) { 'PUL-PUL.1012676.IN.BIB.D20230712.T115732756.1012676.pul.non-pcc_27837389230006421_new.mrc_1.BibExceptionReport.txt' }
    # too old
    let(:file_name_to_skip_one) { 'PUL-PUL.1012676.IN.BIB.D20230526.T144121659.1012676.pul.non-pcc_26337509860006421_new.mrc_1.BibExceptionReport.txt' }
    # different type of report
    let(:file_name_to_skip_two) { 'PUL-PUL.1012676.IN.BIB.D20230712.T115712289.1012676.pul.non-pcc_27837389230006421_new.mrc_2.LbdExceptionReport.txt' }
    let(:temp_file_one) { Tempfile.new(encoding: 'ascii-8bit') }
    let(:temp_file_two) { Tempfile.new(encoding: 'ascii-8bit') }
    let(:freeze_time) { Time.utc(2023, 7, 13) }
    let(:sftp_entry1) { instance_double("Net::SFTP::Protocol::V01::Name", name: file_name_to_download_one) }
    let(:sftp_entry2) { instance_double("Net::SFTP::Protocol::V01::Name", name: file_name_to_skip_one) }
    let(:sftp_entry3) { instance_double("Net::SFTP::Protocol::V01::Name", name: file_name_to_skip_two) }
    let(:sftp_entry4) { instance_double("Net::SFTP::Protocol::V01::Name", name: file_name_to_download_two) }
    let(:sftp_session) { instance_double("Net::SFTP::Session", dir: sftp_dir) }
    let(:sftp_dir) { instance_double("Net::SFTP::Operations::Dir") }
    around do |example|
      Timecop.freeze(freeze_time) do
        example.run
      end
    end

    before do
      allow(Tempfile).to receive(:new).and_return(temp_file_one, temp_file_two)
      allow(sftp_dir).to receive(:foreach).and_yield(sftp_entry1).and_yield(sftp_entry2).and_yield(sftp_entry3).and_yield(sftp_entry4)
      allow(sftp_session).to receive(:download!).with(file_full_path_one, temp_file_one)
      allow(sftp_session).to receive(:download!).with(file_full_path_two, temp_file_two)
      allow(Net::SFTP).to receive(:start).and_yield(sftp_session)
    end

    it 'downloads only the relevant files' do
      expect(data_sync_exception_job.run).to be_truthy
      expect(sftp_session).to have_received(:download!).with(file_full_path_one, temp_file_one)
      expect(sftp_session).to have_received(:download!).with(file_full_path_two, temp_file_two)
    end
  end
end
