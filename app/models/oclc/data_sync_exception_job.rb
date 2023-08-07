# frozen_string_literal: true

module Oclc
  class DataSyncExceptionJob < LibJob
    attr_reader :oclc_sftp, :alma_sftp, :input_sftp_base_dir, :output_sftp_base_dir, :file_pattern, :working_file_directory

    def initialize(oclc_sftp: OclcSftp.new,
                   alma_sftp: AlmaSftp.new,
                   input_sftp_base_dir: Rails.application.config.oclc_sftp.exceptions_input_path,
                   output_sftp_base_dir: Rails.application.config.oclc_sftp.exceptions_output_path,
                   working_file_directory: Rails.application.config.oclc_sftp.exceptions_working_directory)
      super(category: "OclcDataSyncException")
      @input_sftp_base_dir = input_sftp_base_dir
      @output_sftp_base_dir = output_sftp_base_dir
      @file_pattern = 'BibExceptionReport.txt$'
      @oclc_sftp = oclc_sftp
      @alma_sftp = alma_sftp
      @working_file_directory = working_file_directory
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
      working_file_names = process_files_from_oclc
      upload_files_to_alma_sftp(working_file_names:)
      data_set
    end

    def process_files_from_oclc
      working_file_names = []
      oclc_sftp.start do |sftp|
        sftp.dir.foreach(input_sftp_base_dir) do |entry|
          next unless /#{file_pattern}/.match?(entry.name) && date_in_range?(file_name: entry.name)

          Rails.logger.debug { "Found matching pattern in file: #{entry.name}" }
          remote_filename = File.join(input_sftp_base_dir, entry.name)
          # ascii-8bit required for download! to succeed
          temp_file = Tempfile.new(encoding: 'ascii-8bit')
          sftp.download!(remote_filename, temp_file)
          working_file_name = DataSyncExceptionFile.new(temp_file:).process
          working_file_names << working_file_name
        end
      end
      working_file_names
    end

    def date_in_range?(file_name:)
      file_date_str = file_name.match(/.IN.BIB.D(\d{8})/).captures.first
      file_date = Time.zone.parse(file_date_str)
      today = Time.now.utc
      file_date.between?(today - 7.days, today)
    end
  end
end
