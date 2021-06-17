# frozen_string_literal: true

# This class moves files from a samba share populated by PeopleSoft into the sftp directory Alma needs
#  No data transformation is done.
module AlmaFundAdjustment
  class FileTransfer < LibJob
    attr_reader :peoplesoft_input_base_dir, :peoplesoft_input_file_pattern, :alma_fund_adjustment_path, :alma_sftp

    # inputs is an Finance samba share
    # the output is the alma ftp server
    def initialize(peoplesoft_input_base_dir: Rails.application.config.peoplesoft.fund_adjustment_input_path,
                   peoplesoft_input_file_pattern: Rails.application.config.peoplesoft.fund_adjustment_input_file_pattern,
                   alma_sftp: AlmaSftp.new, fund_adjustment_path: Rails.application.config.alma_ftp.fund_adjustment_path)
      super(category: "FundAdjustment")
      @alma_sftp = alma_sftp
      @alma_fund_adjustment_path = fund_adjustment_path
      @peoplesoft_input_base_dir = peoplesoft_input_base_dir
      @peoplesoft_input_file_pattern = peoplesoft_input_file_pattern.gsub("\\*", "*")
    end

    private

    def handle(data_set:)
      data_set.report_time = Time.zone.now.midnight
      files = Dir.glob(File.join(peoplesoft_input_base_dir, peoplesoft_input_file_pattern))
      errors = []
      alma_sftp.start do |sftp|
        files.each do |path|
          proccess_file(path, sftp)
        rescue Net::SFTP::StatusException
          errors << path
        end
      end
      data_set.data = "Files processed: #{join_list(files - errors)};  Error processing: #{join_list(errors)}"
      data_set
    end

    def proccess_file(path, sftp)
      sftp.upload!(path, File.join(alma_fund_adjustment_path, File.basename(path)))
      File.rename(path, "#{path}.processed")
    end

    def join_list(list)
      return 'None' if list.blank?
      list.join(", ")
    end
  end
end
