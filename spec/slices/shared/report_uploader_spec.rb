# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Shared::ReportUploader, :file_upload, type: :model do
  include_context 'sftp'

  let(:uploader) { described_class.new }
  let(:working_file_name_1) { 'datasync_errors_20230713_103005835_1.mrc' }
  let(:working_file_name_2) { 'datasync_errors_20230713_103005835_2.mrc' }
  let(:working_file_directory) { Rails.application.config.oclc_sftp.exceptions_working_directory }
  let(:output_sftp_base_dir) { Rails.application.config.oclc_sftp.datasync_output_path }
  let(:alma_upload_path_1) { "/alma/datasync_processing/#{working_file_name_1}" }
  let(:alma_upload_path_2) { "/alma/datasync_processing/#{working_file_name_2}" }
  let(:new_file_for_alma_path_1) { "spec/fixtures/oclc/exceptions/#{working_file_name_1}" }
  let(:new_file_for_alma_path_2) { "spec/fixtures/oclc/exceptions/#{working_file_name_2}" }
  let(:context) do
    described_class::Context[
      working_file_names: [working_file_name_1, working_file_name_2],
      working_file_directory:,
      output_sftp_base_dir:
    ]
  end

  before do
    allow(sftp_session).to receive(:upload!).with(new_file_for_alma_path_1, alma_upload_path_1)
    allow(sftp_session).to receive(:upload!).with(new_file_for_alma_path_2, alma_upload_path_2)
  end

  it 'can be instantiated' do
    expect(uploader).to be_a(described_class)
  end

  it 'records the upload details in its context' do
    expect(context.working_file_names).to contain_exactly(working_file_name_1, working_file_name_2)
  end

  it 'returns a report of the uploaded file paths' do
    report = uploader.run(context)
    expect(report.uploaded_file_paths).to contain_exactly(alma_upload_path_1, alma_upload_path_2)
    expect(report.errors).to be_empty
    expect(sftp_session).to have_received(:upload!).with(new_file_for_alma_path_1, alma_upload_path_1)
    expect(sftp_session).to have_received(:upload!).with(new_file_for_alma_path_2, alma_upload_path_2)
  end

  it 'can be passed a different sftp connection' do
    oclc_context = described_class::Context[sftp: Shared::Slice['oclc_sftp'],
                                            working_file_names: [working_file_name_1],
                                            working_file_directory:,
                                            output_sftp_base_dir:]
    expect(oclc_context.sftp).to be_an_instance_of(Shared::Sftp)
  end

  describe 'marking a file as processed' do
    let(:context) do
      described_class::Context[
        working_file_names: [working_file_name_1, working_file_name_2],
        working_file_directory:,
        output_sftp_base_dir:,
        mark_as_processed: true
      ]
    end
    let(:orig_file_path_1) { File.join(working_file_directory, working_file_name_1) }
    let(:processed_file_path_1) { File.join(working_file_directory, "#{working_file_name_1}.processed") }
    let(:orig_file_path_2) { File.join(working_file_directory, working_file_name_2) }
    let(:processed_file_path_2) { File.join(working_file_directory, "#{working_file_name_2}.processed") }
    let(:files_for_cleanup) { [orig_file_path_1, orig_file_path_2, processed_file_path_1, processed_file_path_2] }

    before do
      FileUtils.touch(orig_file_path_1)
      FileUtils.touch(orig_file_path_2)
    end

    around do |example|
      files_for_cleanup.each do |file_path|
        File.delete(file_path) if File.exist?(file_path)
      end
      example.run
      files_for_cleanup.each do |file_path|
        File.delete(file_path) if File.exist?(file_path)
      end
    end

    it 'can mark a file as processed' do
      expect(context.mark_as_processed).to be(true)
      expect(File.exist?(processed_file_path_1)).to be false
      uploader.run(context)
      expect(File.exist?(processed_file_path_1)).to be true
      expect(File.exist?(processed_file_path_2)).to be true
    end

    context 'with an sftp upload error' do
      before do
        allow(sftp_session).to receive(:upload!).with(new_file_for_alma_path_1, alma_upload_path_1).and_raise(Net::SFTP::StatusException, Net::SFTP::Response.new({}, { code: 500 }))
      end

      it 'does not include the file in the list of uploaded files' do
        report = uploader.run(context)
        expect(report.uploaded_file_paths).to contain_exactly(alma_upload_path_2)
      end

      it 'does not mark the file with the error as processed' do
        expect(File.exist?(processed_file_path_1)).to be false
        expect(File.exist?(processed_file_path_2)).to be false
        uploader.run(context)
        expect(File.exist?(processed_file_path_1)).to be false
        expect(File.exist?(processed_file_path_2)).to be true
      end

      it 'adds the file with an error to the report errors' do
        report = uploader.run(context)
        expect(report.errors).to contain_exactly(new_file_for_alma_path_1)
      end

      it 'logs the error to the rails error log' do
        allow(Rails.logger).to receive(:error)
        uploader.run(context)
        expect(Rails.logger).to have_received(:error).once.with("Error uploading source file: #{new_file_for_alma_path_1} to sftp path: #{alma_upload_path_1}")
      end

      it 'does not log success to the debug log' do
        allow(Rails.logger).to receive(:debug)
        uploader.run(context)
        expect(Rails.logger).to have_received(:debug).once.with("Uploaded source file: #{new_file_for_alma_path_2} to sftp path: #{alma_upload_path_2}")
        expect(Rails.logger).not_to have_received(:debug).with("Uploaded source file: #{new_file_for_alma_path_1} to sftp path: #{alma_upload_path_1}")
      end
    end
  end
end
