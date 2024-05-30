# frozen_string_literal: true

class ReportUploader
  attr_reader :working_file_names, :working_file_directory, :output_sftp_base_dir, :sftp, :mark_as_processed, :errors
  def initialize(sftp: AlmaSftp.new, working_file_names:, working_file_directory:, output_sftp_base_dir:, mark_as_processed: false)
    @working_file_names = working_file_names
    @working_file_directory = working_file_directory
    @output_sftp_base_dir = output_sftp_base_dir
    @sftp = sftp
    @mark_as_processed = mark_as_processed
    @errors = []
    @uploaded_file_paths = []
  end

  def run
    sftp.start do |sftp_conn|
      working_file_names.each do |working_file_name|
        upload_file(working_file_name, sftp_conn)
      end
    end
    @uploaded_file_paths
  end

  def upload_file(working_file_name, sftp_conn)
    source_file_path = File.join(working_file_directory, working_file_name)
    Rails.logger.debug { "Source file path for sftp upload: #{source_file_path}" }
    destination_file_path = File.join(output_sftp_base_dir, working_file_name)
    Rails.logger.debug { "Destination file path for sftp upload: #{destination_file_path}" }
    sftp_conn.upload!(source_file_path, destination_file_path)
    @uploaded_file_paths << destination_file_path
    Rails.logger.debug("Uploaded source file: #{source_file_path} to sftp path: #{destination_file_path}") # rubocop:disable Rails/EagerEvaluationLogMessage
    mark_file_as_processed(source_file_path) if mark_as_processed
  rescue Net::SFTP::StatusException
    errors << source_file_path
    Rails.logger.error("Error uploading source file: #{source_file_path} to sftp path: #{destination_file_path}")
  end

  def mark_file_as_processed(source_file_path)
    File.rename(source_file_path, "#{source_file_path}.processed")
  end
end
