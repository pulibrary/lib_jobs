# frozen_string_literal: true

module Shared
  # Uploads locally generated report files to a remote sftp server via the
  # supplied sftp connection and reports which files were uploaded and which
  # encountered errors.
  class ReportUploader
    Context = Data.define(:sftp, :working_file_names, :working_file_directory, :output_sftp_base_dir, :mark_as_processed) do
      def initialize(sftp: Slice['alma_sftp'], mark_as_processed: false, **) = super
    end

    Report = Data.define(:uploaded_file_paths, :errors)

    FileUploadResult = Data.define(:uploaded_file_path, :error) do
      def initialize(uploaded_file_path: nil, error: nil) = super
    end

    def run(context)
      uploaded_file_paths = []
      errors = []
      context.sftp.start do |sftp_conn|
        context.working_file_names.each do |working_file_name|
          result = upload_file(working_file_name:, sftp_conn:, context:)
          uploaded_file_paths << result.uploaded_file_path if result.uploaded_file_path
          errors << result.error if result.error
        end
      end
      Report.new(uploaded_file_paths:, errors:)
    end

    private

    def upload_file(working_file_name:, sftp_conn:, context:)
      source_file_path = File.join(context.working_file_directory, working_file_name)
      Rails.logger.debug { "Source file path for sftp upload: #{source_file_path}" }
      destination_file_path = File.join(context.output_sftp_base_dir, working_file_name)
      Rails.logger.debug { "Destination file path for sftp upload: #{destination_file_path}" }
      sftp_conn.upload!(source_file_path, destination_file_path)
      Rails.logger.debug("Uploaded source file: #{source_file_path} to sftp path: #{destination_file_path}") # rubocop:disable Rails/EagerEvaluationLogMessage
      mark_file_as_processed(source_file_path) if context.mark_as_processed
      FileUploadResult.new(uploaded_file_path: destination_file_path)
    rescue Net::SFTP::StatusException
      Rails.logger.error("Error uploading source file: #{source_file_path} to sftp path: #{destination_file_path}")
      FileUploadResult.new(error: source_file_path)
    end

    def mark_file_as_processed(source_file_path)
      File.rename(source_file_path, "#{source_file_path}.processed")
    end
  end
end
