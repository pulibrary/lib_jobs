# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Oclc::ReportUploader, type: :model do
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
  end
end
