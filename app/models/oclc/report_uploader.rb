# frozen_string_literal: true

module Oclc
  class ReportUploader
    attr_reader :working_file_names, :working_file_directory, :output_sftp_base_dir, :alma_sftp
    def initialize(working_file_names:, working_file_directory:, output_sftp_base_dir:)
      @working_file_names = working_file_names
      @working_file_directory = working_file_directory
      @output_sftp_base_dir = output_sftp_base_dir
      @alma_sftp = AlmaSftp.new
    end

    def run
      uploaded_file_paths = []
      alma_sftp.start do |sftp|
        working_file_names.each do |working_file_name|
          source_file_path = File.join(working_file_directory, working_file_name)
          destination_file_path = File.join(output_sftp_base_dir, working_file_name)
          sftp.upload!(source_file_path, destination_file_path)
          uploaded_file_paths << destination_file_path
          Rails.logger.debug { "Uploaded source file: #{source_file_path} to sftp path: #{destination_file_path}" }
        end
      end
      uploaded_file_paths
    end
  end
end
