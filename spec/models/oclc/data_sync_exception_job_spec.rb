# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Oclc::DataSyncExceptionJob, type: :model, file_download: true do
  subject(:data_sync_exception_job) { described_class.new }
  let(:working_file_name_1) { 'datasync_errors_20230713_103005835_1.mrc' }
  let(:working_file_name_2) { 'datasync_errors_20230713_103005835_2.mrc' }
  let(:new_file_for_alma_path_1) { "spec/fixtures/oclc/exceptions/#{working_file_name_1}" }
  let(:new_file_for_alma_path_2) { "spec/fixtures/oclc/exceptions/#{working_file_name_2}" }
  let(:alma_upload_path_1) { "/alma/datasync_processing/#{working_file_name_1}" }
  let(:alma_upload_path_2) { "/alma/datasync_processing/#{working_file_name_2}" }

  it 'can be instantiated' do
    expect(data_sync_exception_job).to be
  end

  context 'with files on the OCLC sftp server' do
    include_context 'sftp'

    let(:input_sftp_base_dir) { Rails.application.config.oclc_sftp.data_sync_report_path }
    let(:file_full_path_one) { "#{input_sftp_base_dir}#{file_name_to_download_one}" }
    let(:file_full_path_two) { "#{input_sftp_base_dir}#{file_name_to_download_two}" }
    let(:oclc_fixture_file_path) { 'spec/fixtures/oclc/PUL-PUL.1012676.IN.BIB.D20230712.T115732756.1012676.pul.non-pcc_27837389230006421_new.mrc_1.BibExceptionReport.txt' }
    let(:oclc_fixture_file_path_two) { 'spec/fixtures/oclc/PUL-PUL.1012676.IN.BIB.D20230712.T115712289.1012676.pul.non-pcc_27837389230006421_new.mrc_2.BibExceptionReport.txt' }
    let(:file_name_to_download_one) { 'PUL-PUL.1012676.IN.BIB.D20230712.T115712289.1012676.pul.non-pcc_27837389230006421_new.mrc_2.BibExceptionReport.txt' }
    let(:file_name_to_download_two) { 'PUL-PUL.1012676.IN.BIB.D20230712.T115732756.1012676.pul.non-pcc_27837389230006421_new.mrc_1.BibExceptionReport.txt' }
    # too old
    let(:file_name_to_skip_one) { 'PUL-PUL.1012676.IN.BIB.D20230526.T144121659.1012676.pul.non-pcc_26337509860006421_new.mrc_1.BibExceptionReport.txt' }
    # different type of report
    let(:file_name_to_skip_two) { 'PUL-PUL.1012676.IN.BIB.D20230712.T115712289.1012676.pul.non-pcc_27837389230006421_new.mrc_2.LbdExceptionReport.txt' }
    let(:temp_file_one) { Tempfile.new(encoding: 'ascii-8bit') }
    let(:temp_file_two) { Tempfile.new(encoding: 'ascii-8bit') }
    let(:freeze_time) { Time.utc(2023, 7, 13, 10, 30, 5, 835_000) }
    let(:sftp_entry1) { instance_double("Net::SFTP::Protocol::V01::Name", name: file_name_to_download_one) }
    let(:sftp_entry2) { instance_double("Net::SFTP::Protocol::V01::Name", name: file_name_to_skip_one) }
    let(:sftp_entry3) { instance_double("Net::SFTP::Protocol::V01::Name", name: file_name_to_skip_two) }
    let(:sftp_entry4) { instance_double("Net::SFTP::Protocol::V01::Name", name: file_name_to_download_two) }

    around do |example|
      File.delete(new_file_for_alma_path_1) if File.exist?(new_file_for_alma_path_1)
      File.delete(new_file_for_alma_path_2) if File.exist?(new_file_for_alma_path_2)
      temp_file_one.write(File.open(oclc_fixture_file_path).read)
      temp_file_two.write(File.open(oclc_fixture_file_path_two).read)
      temp_file_one.rewind
      temp_file_two.rewind
      Timecop.freeze(freeze_time) do
        example.run
      end
      File.delete(new_file_for_alma_path_1) if File.exist?(new_file_for_alma_path_1)
      File.delete(new_file_for_alma_path_2) if File.exist?(new_file_for_alma_path_2)
    end

    before do
      allow(Tempfile).to receive(:new).and_return(temp_file_one, temp_file_two)
      allow(sftp_dir).to receive(:foreach).and_yield(sftp_entry1).and_yield(sftp_entry2).and_yield(sftp_entry3).and_yield(sftp_entry4)
      allow(sftp_session).to receive(:download!).with(file_full_path_one, temp_file_one).and_return(File.read(temp_file_one))
      allow(sftp_session).to receive(:download!).with(file_full_path_two, temp_file_two).and_return(File.read(temp_file_two))
      allow(sftp_session).to receive(:upload!).twice
    end

    context 'with a file with no valid errors' do
      let(:oclc_fixture_file_path) { 'spec/fixtures/oclc/PUL-PUL.1012676.IN.BIB.D20240529.T011306010.1012676.pul.non-pcc_37850317700006421_new.mrc_247.BibExceptionReport.txt' }
      it 'does the right thing' do
        expect(data_sync_exception_job.run).to be_truthy
        expect(sftp_session).to have_received(:download!).with(file_full_path_one, temp_file_one)
        expect(sftp_session).to have_received(:download!).with(file_full_path_two, temp_file_two)
        # Only expect this once, not twice, since only one file has valid errors
        expect(sftp_session).to have_received(:upload!).with(new_file_for_alma_path_1, alma_upload_path_1).once
      end
    end

    it_behaves_like 'a lib job'

    it 'downloads only the relevant files' do
      temp_file_one.rewind
      temp_file_two.rewind
      expect(data_sync_exception_job.run).to be_truthy
      expect(sftp_session).to have_received(:download!).with(file_full_path_one, temp_file_one)
      expect(sftp_session).to have_received(:download!).with(file_full_path_two, temp_file_two)
    end

    it 'uploads working files to lib-sftp' do
      data_sync_exception_job.run
      # The two upload paths are the same in the test environment because usually the timestamp
      # would be different, but we've frozen time for the rest of the tests & mocks to work
      expect(sftp_session).to have_received(:upload!).with(new_file_for_alma_path_1, alma_upload_path_1).twice
    end

    it 'records data to display in the UI' do
      data_sync_exception_job.run
      data_set = DataSet.last
      expect(data_set.report_time).to eq(Time.zone.now)
      # The two upload paths are the same in the test environment because usually the timestamp
      # would be different, but we've frozen time for the rest of the tests & mocks to work
      expect(data_set.data).to eq("Files created and uploaded to lib-sftp: " \
        "#{alma_upload_path_1}, #{alma_upload_path_1}.")
    end

    context 'with an upload error' do
      before do
        allow(sftp_session).to receive(:upload!).with(new_file_for_alma_path_1, alma_upload_path_1).and_raise(Net::SFTP::StatusException, Net::SFTP::Response.new({}, { code: 500 }))
      end
      it 'records the error in the data' do
        data_sync_exception_job.run
        data_set = DataSet.last
        expect(data_set.report_time).to eq(Time.zone.now)
        expect(data_set.data).to eq("Files created and uploaded to lib-sftp: None." \
        " Files with upload errors: #{new_file_for_alma_path_1}, #{new_file_for_alma_path_1}.")
      end
    end
  end
end
