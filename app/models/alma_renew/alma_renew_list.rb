# frozen_string_literal: true
# access alma xml invoice list and make it accessible for processing
require 'csv'

module AlmaRenew
  class AlmaRenewList
    attr_reader :renew_items, :alma_sftp, :file_pattern, :input_ftp_base_dir, :sftp_locations

    BOM = "\xEF\xBB\xBF"

    delegate :empty?, to: :valid_invoices

    def initialize(input_ftp_base_dir: Rails.application.config.alma_ftp.renew_report_path, file_pattern: '\.csv$', alma_sftp: AlmaSftp.new)
      @input_ftp_base_dir = input_ftp_base_dir
      @file_pattern = file_pattern
      @alma_sftp = alma_sftp
      @renew_items, @sftp_locations = download_renew_items
    end

    def mark_files_as_processed
      alma_sftp.start do |sftp|
        sftp_locations.each do |location|
          sftp.rename(location, "#{location}.processed")
        end
      end
    end

    private

    def download_renew_items
      renew_items = []
      sftp_locations = []
      alma_sftp.start do |sftp|
        sftp.dir.foreach(input_ftp_base_dir) do |entry|
          next unless /#{file_pattern}/.match?(entry.name)
          filename = File.join(input_ftp_base_dir, entry.name)
          data = sftp.download!(filename)
          CSV.parse(data.delete_prefix(BOM), headers: true) do |row|
            renew_items << row.to_h
          end

          sftp_locations << filename
        end
      end
      [renew_items, sftp_locations]
    end
  end
end
