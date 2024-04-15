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
                   fund_adjustment_path: Rails.application.config.alma_sftp.fund_adjustment_path,
                   sftp: AlmaSftp.new, working_file_directory: Rails.application.config.peoplesoft.fund_adjustment_converted_path)
      super
      @processed_directory = Rails.application.config.peoplesoft.fund_adjustment_converted_path
    end

    private

    def process_files
    end

    def process_file(source_file_path, sftp_conn) # rubocop:disable Metrics/MethodLength
      adjusted_data = create_adjusted_file(source_file_path)
      return if adjusted_data.blank?
      source_file_name = File.basename(source_file_path)
      working_file_path = File.join(processed_directory, source_file_name)

      destination_file_path = File.join(output_sftp_base_dir, source_file_name)
      sftp_conn.upload!(working_file_path, destination_file_path)
      Rails.logger.debug { "Uploaded source file: #{working_file_path} to sftp path: #{destination_file_path}" }
      mark_file_as_processed(source_file_path)
      destination_file_path
    end

    def create_adjusted_file(source_file_path)
      data = read_file(source_file_path)
      mark_file_as_processed(source_file_path) && return if data.empty?

      adjustments = data.map { |row| FundAdjustment.new(row).adjusted_row }

      source_file_name = File.basename(source_file_path)
      working_file_path = File.join(processed_directory, source_file_name)

      CSV.open(working_file_path, "wb") do |csv|
        csv << adjustments.first.headers
        adjustments.each do |row|
          csv << row
        end
      end
    end

    def read_file(path)
      data = CSV.read(path, headers: true)
      return data if data.empty?
      CSVValidator.new(csv_filename: path)
                  .require_headers(['TRANSACTION_REFERENCE_NUMBER', 'TRANSACTION_NOTE', 'AMOUNT'])
      data
    end
  end
end
