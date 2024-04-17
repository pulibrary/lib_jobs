# frozen_string_literal: true
# access alma xml invoice list and make it accessible for processing
require 'csv'

module AlmaRenew
  class AlmaRenewList
    attr_reader :renew_item_list, :sftp, :file_pattern, :input_sftp_base_dir, :remote_filenames

    BOM = "\xEF\xBB\xBF"

    delegate :empty?, to: :valid_invoices

    def initialize(input_sftp_base_dir: Rails.application.config.alma_sftp.renew_report_path, file_pattern: '\.csv$', alma_sftp: AlmaSftp.new)
      @input_sftp_base_dir = input_sftp_base_dir
      @file_pattern = file_pattern
      @sftp = alma_sftp
      @renew_item_list = []
      @remote_filenames = []
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

    # rubocop:disable Metrics/MethodLength
    def download_renew_items
      # report_downloader = ReportDownloader.new(sftp: AlmaSftp.new, file_pattern:, process_class: AlmaRenew::AlmaRenewList, input_sftp_base_dir:)
      # report_downloader.run
      working_file_names = []
      sftp.start do |sftp_conn|
        sftp_conn.dir.foreach(input_sftp_base_dir) do |entry|
          next if /\.processed$/.match?(entry.name)
          next unless /#{file_pattern}/.match?(entry.name) && date_in_range?(file_name: entry.name)

          Rails.logger.debug { "Found matching pattern in file: #{entry.name}" }
          remote_filename = File.join(input_sftp_base_dir, entry.name)
          # ascii-8bit required for download! to succeed
          temp_file = Tempfile.new(encoding: 'ascii-8bit')
          sftp_conn.download!(remote_filename, temp_file)
          process(temp_file)
          remote_filenames << remote_filename
        end
      end
      working_file_names
    end

    # rubocop:enable Metrics/MethodLength
    def date_in_range?(*)
      true
    end

    def process(temp_file)
      CSVValidator.new(csv_filename: temp_file.path).require_headers ['Barcode', 'Patron Group', 'Expiry Date', 'Primary Identifier']
      CSV.foreach(temp_file, headers: true, encoding: 'bom|utf-8') do |row|
        renew_item_list << Item.new(row.to_h)
      end
      renew_item_list
    end
  end
end
