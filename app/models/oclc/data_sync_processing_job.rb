# frozen_string_literal: true

module Oclc
  class DataSyncProcessingJob < LibJob
    attr_reader :report_downloader, :working_file_directory, :output_sftp_base_dir

    def initialize(report_downloader: Oclc::ReportDownloader.new(file_pattern: 'BibProcessingReport.txt$',
                                                                 process_class: Oclc::DataSyncProcessingFile,
                                                                 input_sftp_base_dir: Rails.application.config.oclc_sftp.data_sync_report_path,
                                                                 recent: true))
      super(category: "Oclc:DataSyncProcessing")
      @report_downloader = report_downloader
      @working_file_directory = Rails.application.config.oclc_sftp.processing_working_directory
      @output_sftp_base_dir = Rails.application.config.oclc_sftp.datasync_output_path
    end

    private

    def handle(data_set:)
      data_set.report_time = Time.zone.now.midnight

      working_file_names = report_downloader.run
      report_uploader = ReportUploader.new(working_file_names:,
                                           working_file_directory:,
                                           output_sftp_base_dir:)
      uploaded_file_paths = report_uploader.run
      data_set.data = "Files created and uploaded to lib-sftp: #{uploaded_file_paths.join(', ')}"

      data_set
    end
  end
end
