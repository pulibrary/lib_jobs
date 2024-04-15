# frozen_string_literal: true

# This class moves files from a samba share populated by PeopleSoft into the sftp directory Alma needs
#  No data transformation is done.
module AlmaFundAdjustment
  class FileTransfer < LibJob
    attr_reader :peoplesoft_input_base_dir, :peoplesoft_input_file_pattern, :alma_fund_adjustment_path,
    :sftp, :errors, :output_sftp_base_dir, :files_to_upload, :working_file_directory

    # inputs is an Finance samba share
    # the output is the alma ftp server
    def initialize(peoplesoft_input_base_dir: Rails.application.config.peoplesoft.fund_adjustment_input_path,
                   peoplesoft_input_file_pattern: Rails.application.config.peoplesoft.fund_adjustment_input_file_pattern,
                   fund_adjustment_path: Rails.application.config.alma_sftp.fund_adjustment_path,
                   sftp: AlmaSftp.new, working_file_directory: Rails.application.config.peoplesoft.fund_adjustment_input_path)
      super(category: "FundAdjustment")
      @sftp = sftp
      @alma_fund_adjustment_path = fund_adjustment_path
      @peoplesoft_input_base_dir = peoplesoft_input_base_dir
      @peoplesoft_input_file_pattern = peoplesoft_input_file_pattern.gsub("\\*", "*")
      @output_sftp_base_dir = fund_adjustment_path
      @working_file_directory = working_file_directory
      @errors = []
    end

    private

    def handle(data_set:)
      data_set.report_time = Time.zone.now.midnight
      working_file_names = process_files
      uploader = ReportUploader.new(working_file_names:, working_file_directory:, output_sftp_base_dir:, mark_as_processed: true)
      # uploader.run
      future_run
      data_set.data = "Files processed: #{join_list(source_file_paths - errors)};  Error processing: #{join_list(errors)}"
      data_set
    end

    def process_files
      source_file_names
    end

    def future_run
      uploaded_file_paths = []
      sftp.start do |sftp_conn|
        source_file_names.each do |source_file_name|
          source_file_path = File.join(peoplesoft_input_base_dir, source_file_name)
          uploaded_file_paths << process_file(source_file_path, sftp_conn)
        rescue Net::SFTP::StatusException
          errors << source_file_path
        end
      end
      uploaded_file_paths
    end

    # These should be the names of the files to upload
    # For the base class, this is the same as the source file names
    # For one file converter it's the .updated paths
    # For the other it's the .converted paths
    # def working_file_names
    #   @working_file_names ||= source_file_names
    # end

    def source_file_names
      @source_file_names ||= source_file_paths.map { |path| File.basename(path) }
    end

    def source_file_paths
      @source_file_paths ||= Dir.glob(File.join(peoplesoft_input_base_dir, peoplesoft_input_file_pattern))
    end

    def process_file(source_file_path, sftp_conn)
      source_file_name = File.basename(source_file_path)
      destination_file_path = File.join(output_sftp_base_dir, source_file_name)
      sftp_conn.upload!(source_file_path, destination_file_path)
      Rails.logger.debug { "Uploaded source file: #{source_file_path} to sftp path: #{destination_file_path}" }
      mark_file_as_processed(source_file_path)
      destination_file_path
    end

    def join_list(list)
      return 'None' if list.blank?
      list.join(", ")
    end

    def mark_file_as_processed(source_file_path)
      File.rename(source_file_path, "#{source_file_path}.processed")
    end
  end
end
