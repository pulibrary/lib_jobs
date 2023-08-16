# frozen_string_literal: true

module Oclc
  class DataSyncExceptionJob < LibJob
    attr_reader :report_downloader, :alma_sftp, :working_file_directory, :output_sftp_base_dir

    def initialize(report_downloader: Oclc::ReportDownloader.new(file_pattern: 'BibExceptionReport.txt$',
                                                                 process_class: Oclc::DataSyncExceptionFile,
                                                                 input_sftp_base_dir: Rails.application.config.oclc_sftp.data_sync_report_path,
                                                                 recent: true),
                   alma_sftp: AlmaSftp.new,
                   working_file_directory: Rails.application.config.oclc_sftp.exceptions_working_directory,
                   output_sftp_base_dir: Rails.application.config.oclc_sftp.exceptions_output_path)
      super(category: "OclcDataSyncException")
      @report_downloader = report_downloader
      @alma_sftp = alma_sftp
      @working_file_directory = working_file_directory
      @output_sftp_base_dir = output_sftp_base_dir
    end

    def upload_files_to_alma_sftp(working_file_names:)
      uploaded_file_paths = []
      alma_sftp.start do |sftp|
        working_file_names.each do |working_file_name|
          source_file_path = File.join(working_file_directory, working_file_name)
          destination_file_path = File.join(output_sftp_base_dir, working_file_name)
          sftp.upload!(source_file_path, destination_file_path)
          uploaded_file_paths << destination_file_path
          Rails.logger.debug { "Uploaded source file: #{source_file_path} to sftp path: #{destination_file_path}" }
        end
      end
      uploaded_file_paths
    end

    private

    def handle(data_set:)
      working_file_names = report_downloader.run
      uploaded_file_paths = upload_files_to_alma_sftp(working_file_names:)
      data_set.data = "Files created and uploaded to lib-sftp: #{uploaded_file_paths.join(', ')}"
      data_set
    end
  end
end
