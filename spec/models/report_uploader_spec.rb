# frozen_string_literal: true
require 'rails_helper'

RSpec.describe ReportUploader, type: :model, focus: true do
  include_context 'sftp'
  context 'error report' do
    let(:subject) do
      described_class.new(
        working_file_names: [working_file_name_1, working_file_name_2],
        working_file_directory: Rails.application.config.oclc_sftp.exceptions_working_directory,
        output_sftp_base_dir: Rails.application.config.oclc_sftp.datasync_output_path
      )
    end
    let(:working_file_name_1) { 'datasync_errors_20230713_103005835_1.mrc' }
    let(:working_file_name_2) { 'datasync_errors_20230713_103005835_2.mrc' }
    let(:alma_upload_path_1) { "/alma/datasync_processing/#{working_file_name_1}" }
    let(:alma_upload_path_2) { "/alma/datasync_processing/#{working_file_name_2}" }
    let(:new_file_for_alma_path_1) { "spec/fixtures/oclc/exceptions/#{working_file_name_1}" }
    let(:new_file_for_alma_path_2) { "spec/fixtures/oclc/exceptions/#{working_file_name_2}" }

    before do
      allow(sftp_session).to receive(:upload!).with(new_file_for_alma_path_1, alma_upload_path_1)
      allow(sftp_session).to receive(:upload!).with(new_file_for_alma_path_2, alma_upload_path_2)
    end
    it 'can be instantiated' do
      expect(subject).to be
      expect(subject.working_file_names).to match_array([working_file_name_1, working_file_name_2])
    end

    it 'returns an array of uploaded file paths' do
      expect(subject.run).to match_array([alma_upload_path_1, alma_upload_path_2])
      expect(sftp_session).to have_received(:upload!).with(new_file_for_alma_path_1, alma_upload_path_1)
      expect(sftp_session).to have_received(:upload!).with(new_file_for_alma_path_2, alma_upload_path_2)
    end

    it 'defaults to AlmaSftp' do
      expect(subject.sftp).to be_an_instance_of(AlmaSftp)
    end
    context 'with a different sftp connection' do
      let(:subject) do
        described_class.new(
          sftp: OclcSftp.new,
          working_file_names: [working_file_name_1, working_file_name_2],
          working_file_directory: Rails.application.config.oclc_sftp.exceptions_working_directory,
          output_sftp_base_dir: Rails.application.config.oclc_sftp.datasync_output_path
        )
      end
      it 'can be passed a different sftp connection' do
        expect(subject.sftp).to be_an_instance_of(OclcSftp)
      end
    end

    describe 'marking a file as processed' do
      let(:subject) do
        described_class.new(
          working_file_names: [working_file_name_1, working_file_name_2],
          working_file_directory: Rails.application.config.oclc_sftp.exceptions_working_directory,
          output_sftp_base_dir: Rails.application.config.oclc_sftp.datasync_output_path,
          mark_as_processed: true
        )
      end
      let(:orig_file_path_1) { File.join(subject.working_file_directory, working_file_name_1) }
      let(:processed_file_path_1) { File.join(subject.working_file_directory, "#{working_file_name_1}.processed") }
      let(:orig_file_path_2) { File.join(subject.working_file_directory, working_file_name_2) }
      let(:processed_file_path_2) { File.join(subject.working_file_directory, "#{working_file_name_2}.processed") }

      before do
        FileUtils.touch(orig_file_path_1)
        FileUtils.touch(orig_file_path_2)
      end

      around do |example|
        File.delete(orig_file_path_1) if File.exist?(orig_file_path_1)
        File.delete(orig_file_path_2) if File.exist?(orig_file_path_2)
        File.delete(processed_file_path_1) if File.exist?(processed_file_path_1)
        File.delete(processed_file_path_2) if File.exist?(processed_file_path_2)
        example.run
        File.delete(orig_file_path_1) if File.exist?(orig_file_path_1)
        File.delete(orig_file_path_2) if File.exist?(orig_file_path_2)
        File.delete(processed_file_path_1) if File.exist?(processed_file_path_1)
        File.delete(processed_file_path_2) if File.exist?(processed_file_path_2)
      end
      it 'can mark a file as processed' do
        expect(subject.mark_as_processed).to eq(true)
        expect(File.exist?(processed_file_path_1)).to be false
        subject.run
        expect(File.exist?(processed_file_path_1)).to be true
      end
    end
  end
end
