# frozen_string_literal: true
# access alma xml invoice list and make it accessible for processing

module AlmaRenew
  class AlmaRenewList
    attr_reader :renew_item_list, :sftp, :file_pattern, :input_sftp_base_dir, :remote_filenames

    delegate :empty?, to: :valid_invoices

    def initialize(input_sftp_base_dir: Rails.application.config.alma_sftp.renew_report_path, file_pattern: '\.csv$', alma_sftp: AlmaSftp.new)
      @input_sftp_base_dir = input_sftp_base_dir
      @file_pattern = file_pattern
      @sftp = alma_sftp
      download_renew_items
    end

    def mark_files_as_processed
      sftp.start do |sftp_conn|
        remote_filenames.each do |location|
          sftp_conn.rename(location, "#{location}.processed")
        end
      end
    end

    private

    def download_renew_items
      report_downloader = ReportDownloader.new(sftp: AlmaSftp.new, file_pattern:, process_class: AlmaRenew::RenewFile, input_sftp_base_dir:)
      @renew_item_list = report_downloader.run.flatten
      @remote_filenames = report_downloader.remote_filenames
    end
  end
end
