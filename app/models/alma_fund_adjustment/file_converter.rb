# frozen_string_literal: true
require 'csv'

# This class moves files from a samba share populated by PeopleSoft into the sftp directory Alma needs
#  The sign is flipped on the amount before the file is transferred.
module AlmaFundAdjustment
  class FileConverter < FileTransfer
    attr_reader :processed_directory

    # inputs is an Finance samba share
    # the output is the alma ftp server
    def initialize(peoplesoft_input_base_dir: Rails.application.config.peoplesoft.fund_adjustment_input_path,
                   peoplesoft_input_file_pattern: Rails.application.config.peoplesoft.fund_adjustment_input_file_pattern,
                   alma_sftp: AlmaSftp.new, fund_adjustment_path: Rails.application.config.alma_ftp.fund_adjustment_path)
      super
      @processed_directory = Rails.application.config.peoplesoft.fund_adjustment_converted_path
    end

    private

    def process_file(path, sftp)
      data = read_file path
      File.rename(path, "#{path}.processed") && return if data.size.zero?

      adjustments = data.map { |row| FundAdjustment.new(row).adjusted_row }
      base_name = File.basename(path)
      adjusted_file = File.join(processed_directory, "#{base_name}.updated")
      CSV.open(File.join(processed_directory, "#{base_name}.updated"), "wb") do |csv|
        csv << adjustments.first.headers
        adjustments.each do |row|
          csv << row
        end
      end

      sftp.upload!(adjusted_file, File.join(alma_fund_adjustment_path, base_name))
      File.rename(path, "#{path}.processed")
    end

    def read_file(path)
      data = CSV.read(path, headers: true)
      return data if data.size.zero?
      CSVValidator.new(csv_filename: path)
                  .require_headers(['TRANSACTION_REFERENCE_NUMBER', 'TRANSACTION_NOTE', 'AMOUNT'])
      data
    end
  end
end
