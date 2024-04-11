# frozen_string_literal: true

# This class moves files from a samba share populated by PeopleSoft into the sftp directory Alma needs
#  No data transformation is done.
module AlmaFundAdjustment
  class FileTransfer < LibJob
    attr_reader :peoplesoft_input_base_dir, :peoplesoft_input_file_pattern, :alma_fund_adjustment_path, :sftp

    # inputs is an Finance samba share
    # the output is the alma ftp server
    def initialize(peoplesoft_input_base_dir: Rails.application.config.peoplesoft.fund_adjustment_input_path,
                   peoplesoft_input_file_pattern: Rails.application.config.peoplesoft.fund_adjustment_input_file_pattern,
                   alma_sftp: AlmaSftp.new, fund_adjustment_path: Rails.application.config.alma_sftp.fund_adjustment_path)
      super(category: "FundAdjustment")
      @sftp = alma_sftp
      @alma_fund_adjustment_path = fund_adjustment_path
      @peoplesoft_input_base_dir = peoplesoft_input_base_dir
      @peoplesoft_input_file_pattern = peoplesoft_input_file_pattern.gsub("\\*", "*")
    end

    private

    def handle(data_set:)
      data_set.report_time = Time.zone.now.midnight
      files = Dir.glob(File.join(peoplesoft_input_base_dir, peoplesoft_input_file_pattern))
      errors = []
      sftp.start do |sftp_conn|
        files.each do |path|
          process_file(path, sftp_conn)
        rescue Net::SFTP::StatusException
          errors << path
        end
      end
      data_set.data = "Files processed: #{join_list(files - errors)};  Error processing: #{join_list(errors)}"
      data_set
    end

    def process_file(path, sftp_conn)
      sftp_conn.upload!(path, File.join(alma_fund_adjustment_path, File.basename(path)))
      mark_file_as_processed(path)
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
