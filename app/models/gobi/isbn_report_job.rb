# frozen_string_literal: true

module Gobi
  class IsbnReportJob < LibJob
    attr_reader :report_downloader

    def initialize
      super(category: 'Gobi:IsbnReports')
      @report_downloader = ReportDownloader.new(
        sftp: AlmaSftp.new,
        file_pattern: 'received_items_published_last_5_years_\d{12}.csv',
        input_sftp_base_dir: '/alma/isbns'
      )
    end

    def self.working_file_path
      working_file_directory = Rails.application.config.gobi_sftp.working_directory
      FileUtils.mkdir_p(working_file_directory) unless File.exist?(working_file_directory)
      File.join(working_file_directory, IsbnReportJob.working_file_name)
    end

    def self.working_file_name
      date = Time.now.utc.strftime('%Y-%m-%d')
      "#{date}-gobi-isbn-updates.tsv"
    end

    def handle(data_set:)
      temp_files = @report_downloader.download
      create_csv
      temp_files.each do |temp_file|
        Gobi::IsbnFile.new(received_items_file: temp_file).process
      end
      data_set
    end

    def create_csv
      headers = ['isbn', 'code_string', 'account_code']
      CSV.open(IsbnReportJob.working_file_path, 'w', encoding: 'bom|utf-8', col_sep: "\t") do |csv|
        csv << headers
      end
    end
  end
end
