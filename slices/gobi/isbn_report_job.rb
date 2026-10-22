# frozen_string_literal: true

require 'csv'

module Gobi
  class IsbnReportJob < LibJob
    include Deps['settings', 'gobi_sftp', 'shared.alma_sftp', 'shared.report_downloader']

    def category = 'Gobi:IsbnReports'

    private

    def handle(data_set:)
      create_csv
      remote_filenames = report_downloader.run(
        Shared::ReportDownloader::Context[
          sftp: alma_sftp,
          file_pattern: 'received_items_published_last_5_years_\d{12}.csv',
          input_sftp_base_dir: '/alma/isbns',
          process_class: IsbnFile
        ]
      ).remote_filenames
      report_uploader.run
      rename_files_on_sftp(remote_filenames)
      data_set.data = "Number of ISBNs sent: #{CSV.read(working_file_path).length}"
      data_set
    end

    def report_uploader
      ReportUploader.new(
        sftp: gobi_sftp,
        working_file_names: [working_file_name],
        working_file_directory: settings.gobi_sftp_working_directory,
        output_sftp_base_dir: settings.gobi_sftp_output_sftp_base_dir
      )
    end

    def rename_files_on_sftp(remote_filenames)
      alma_sftp.start do |sftp|
        remote_filenames.each do |file_name|
          sftp.rename(file_name, "#{file_name}.processed")
        end
      end
    end

    def create_csv
      CSV.open(working_file_path, 'w', encoding: 'bom|utf-8', col_sep: '|')
    end

    def working_file_name
      date = Time.now.utc.strftime('%Y-%m-%d')
      "#{date}-gobi-isbn-updates.txt"
    end

    def working_file_path
      working_file_directory = settings.gobi_sftp_working_directory
      FileUtils.mkdir_p(working_file_directory) unless File.exist?(working_file_directory)
      File.join(working_file_directory, working_file_name)
    end
  end
end
