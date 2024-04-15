# frozen_string_literal: true

module Oclc
  class DataSyncExceptionJob < LibJob
    attr_reader :report_downloader, :alma_sftp, :working_file_directory, :output_sftp_base_dir

    def initialize(report_downloader: ReportDownloader.new(file_pattern: 'BibExceptionReport.txt$',
                                                           process_class: Oclc::DataSyncExceptionFile,
                                                           input_sftp_base_dir: Rails.application.config.oclc_sftp.data_sync_report_path,
                                                           recent: true),
                   alma_sftp: AlmaSftp.new,
                   working_file_directory: Rails.application.config.oclc_sftp.exceptions_working_directory,
                   output_sftp_base_dir: Rails.application.config.oclc_sftp.datasync_output_path)
      super(category: "Oclc:DataSyncException")
      @report_downloader = report_downloader
      @alma_sftp = alma_sftp
      @working_file_directory = working_file_directory
      @output_sftp_base_dir = output_sftp_base_dir
    end

    private

    def handle(data_set:)
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
