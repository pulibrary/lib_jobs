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
      working_file_names = []
      sftp.start do |sftp_conn|
        sftp_conn.dir.foreach(input_sftp_base_dir) do |entry|
          next if /\.processed$/.match?(entry.name)
          next unless /#{file_pattern}/.match?(entry.name) && date_in_range?(file_name: entry.name)

          Rails.logger.debug { "Found matching pattern in file: #{entry.name}" }
          remote_filename = File.join(input_sftp_base_dir, entry.name)
          # ascii-8bit required for download! to succeed
          Tempfile.new(encoding: 'ascii-8bit')
          data = sftp_conn.download!(remote_filename)
          CSVValidator.new(csv_string: data).require_headers ['Barcode', 'Patron Group', 'Expiry Date', 'Primary Identifier']
          CSV.parse(data.delete_prefix(BOM), headers: true) do |row|
            renew_item_list << Item.new(row.to_h)
          end
          remote_filenames << remote_filename
        end
      end
      working_file_names
    end

    # rubocop:enable Metrics/MethodLength
    def date_in_range?(*)
      true
    end
  end
end
