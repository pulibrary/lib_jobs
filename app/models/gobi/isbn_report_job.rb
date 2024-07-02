# frozen_string_literal: true
require 'csv'

module Gobi
  class IsbnReportJob < LibJob
    attr_reader :report_downloader, :report_uploader

    def initialize
      super(category: 'Gobi:IsbnReports')
      @report_downloader = ReportDownloader.new(
        sftp: AlmaSftp.new,
        file_pattern: 'received_items_published_last_5_years_\d{12}.csv',
        input_sftp_base_dir: '/alma/isbns',
        process_class: Gobi::IsbnFile
      )
      @report_uploader = ReportUploader.new(
        sftp: GobiSftp.new,
        working_file_names: [IsbnReportJob.working_file_name],
        working_file_directory: Rails.application.config.gobi_sftp.working_directory,
        output_sftp_base_dir: Rails.application.config.gobi_sftp.output_sftp_base_dir
      )
    end

    def self.working_file_path
      working_file_directory = Rails.application.config.gobi_sftp.working_directory
      FileUtils.mkdir_p(working_file_directory) unless File.exist?(working_file_directory)
      File.join(working_file_directory, IsbnReportJob.working_file_name)
    end

    def self.working_file_name
      date = Time.now.utc.strftime('%Y-%m-%d')
      "#{date}-gobi-isbn-updates.txt"
    end

    def handle(data_set:)
      create_csv
      report_downloader.run
      report_uploader.run
      rename_files_on_sftp
      data_set.data = "Number of ISBNs sent: #{CSV.read(IsbnReportJob.working_file_path).length}"
      data_set
    end

    def rename_files_on_sftp
      AlmaSftp.new.start do |sftp|
        report_downloader.remote_filenames.each do |file_name|
          sftp.rename(file_name, "#{file_name}.processed")
        end
      end
    end

    def create_csv
      CSV.open(IsbnReportJob.working_file_path, 'w', encoding: 'bom|utf-8', col_sep: "|")
    end
  end
end
