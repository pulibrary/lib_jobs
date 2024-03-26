# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Oclc::DataSyncProcessingJob, type: :model do
  include_context 'sftp'

  subject(:processing_job) { described_class.new }
  let(:working_file_name_1) { 'xref_report_20230713_103005835_1.mrc' }
  let(:working_file_name_2) { 'xref_report_20230713_103005835_2.mrc' }
  let(:new_file_for_alma_path_1) { "spec/fixtures/oclc/processing/#{working_file_name_1}" }
  let(:new_file_for_alma_path_2) { "spec/fixtures/oclc/processing/#{working_file_name_2}" }

  it 'can be instantiated' do
    expect(processing_job).to be
  end

  context 'with files on the OCLC sftp server' do
    let(:input_sftp_base_dir) { Rails.application.config.oclc_sftp.data_sync_report_path }
    let(:file_full_path_one) { "#{input_sftp_base_dir}#{file_name_to_download_one}" }
    let(:file_full_path_two) { "#{input_sftp_base_dir}#{file_name_to_download_two}" }
    let(:oclc_fixture_file_path) { 'spec/fixtures/oclc/PUL-PUL.1012676.IN.BIB.D20230712.T091935658.1012676.pul.non-pcc_28150407720006421_new.mrc_1.BibProcessingReport.txt' }
    let(:file_name_to_download_one) { 'PUL-PUL.1012676.IN.BIB.D20230712.T091935658.1012676.pul.non-pcc_28150407720006421_new.mrc_1.BibProcessingReport.txt' }
    let(:file_name_to_download_two) { 'PUL-PUL.1012676.IN.BIB.D20230712.T091924073.1012676.pul.non-pcc_28150407720006421_new.mrc_2.BibProcessingReport.txt' }
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
      Timecop.freeze(freeze_time) do
        example.run
      end
      File.delete(new_file_for_alma_path_1) if File.exist?(new_file_for_alma_path_1)
      File.delete(new_file_for_alma_path_2) if File.exist?(new_file_for_alma_path_2)
    end

    before do
      allow(Tempfile).to receive(:new).and_return(temp_file_one, temp_file_two)
      allow(sftp_dir).to receive(:foreach).and_yield(sftp_entry1).and_yield(sftp_entry2).and_yield(sftp_entry3).and_yield(sftp_entry4)
      allow(sftp_session).to receive(:download!).with(file_full_path_one, temp_file_one)
      allow(sftp_session).to receive(:download!).with(file_full_path_two, temp_file_two)
      allow(sftp_session).to receive(:upload!).twice
    end

    it_behaves_like 'a lib job'

    it 'downloads only the relevant files' do
      expect(processing_job.run).to be_truthy
      expect(sftp_session).to have_received(:download!).with(file_full_path_one, temp_file_one)
      expect(sftp_session).to have_received(:download!).with(file_full_path_two, temp_file_two)
    end

    it 'uploads working files to lib-sftp' do
      processing_job.run
      expect(sftp_session).to have_received(:upload!).with(new_file_for_alma_path_1, "/alma/datasync_processing/#{working_file_name_1}").twice
    end
  end
end
