# frozen_string_literal: true

# This class moves files from a samba share populated by PeopleSoft into the sftp directory Alma needs
#  No data transformation is done.
module AlmaFundAdjustment
  class FileTransfer < LibJob
    attr_reader :working_file_directory, :peoplesoft_input_file_pattern, :alma_fund_adjustment_path, :sftp, :errors, :output_sftp_base_dir

    # inputs is an Finance samba share
    # the output is the alma ftp server
    def initialize(peoplesoft_input_base_dir: Rails.application.config.peoplesoft.fund_adjustment_input_path,
                   peoplesoft_input_file_pattern: Rails.application.config.peoplesoft.fund_adjustment_input_file_pattern,
                   fund_adjustment_path: Rails.application.config.alma_sftp.fund_adjustment_path,
                   sftp: AlmaSftp.new)
      super(category: "FundAdjustment")
      @sftp = sftp
      @output_sftp_base_dir = fund_adjustment_path
      @alma_fund_adjustment_path = fund_adjustment_path
      @working_file_directory = peoplesoft_input_base_dir
      @peoplesoft_input_file_pattern = peoplesoft_input_file_pattern.gsub("\\*", "*")
      @errors = []
    end

    private

    def handle(data_set:)
      data_set.report_time = Time.zone.now.midnight
      future_run
      data_set.data = "Files processed: #{join_list(working_file_paths - errors)};  Error processing: #{join_list(errors)}"
      data_set
    end

    def future_run
      uploaded_file_paths = []
      sftp.start do |sftp_conn|
        working_file_names.each do |working_file_name|
          source_file_path = File.join(working_file_directory, working_file_name)
          uploaded_file_paths << process_file(source_file_path, sftp_conn)
        rescue Net::SFTP::StatusException
          errors << source_file_path
        end
      end
      uploaded_file_paths
    end

    def working_file_names
      @working_file_names ||= working_file_paths.map { |path| File.basename(path) }
    end

    def working_file_paths
      @working_file_paths ||= Dir.glob(File.join(working_file_directory, peoplesoft_input_file_pattern))
    end

    def process_file(source_file_path, sftp_conn)
      working_file_name = File.basename(source_file_path)
      destination_file_path = File.join(output_sftp_base_dir, working_file_name)
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
