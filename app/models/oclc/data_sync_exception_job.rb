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
      alma_sftp.start do |sftp|
        working_file_names.each do |working_file_name|
          source_file_path = File.join(working_file_directory, working_file_name)
          destination_file_path = File.join(output_sftp_base_dir, working_file_name)
          sftp.upload!(source_file_path, destination_file_path)
          Rails.logger.debug { "Uploaded source file: #{source_file_path} to sftp path: #{destination_file_path}" }
        end
      end
    end

    private

    def handle(data_set:)
      data_set.report_time = Time.zone.now.midnight

      working_file_names = report_downloader.run
      upload_files_to_alma_sftp(working_file_names:)
      data_set
    end

    def date_in_range?(file_name:)
      file_date_str = file_name.match(/.IN.BIB.D(\d{8})/).captures.first
      file_date = Time.zone.parse(file_date_str)
      today = Time.now.utc
      file_date.between?(today - 7.days, today)
    end
  end
end
