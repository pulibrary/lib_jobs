# frozen_string_literal: true

module Oclc
  class DataSyncExceptionJob < LibJob
    attr_reader :oclc_sftp, :input_sftp_base_dir, :file_pattern

    def initialize(oclc_sftp: OclcSftp.new,
                   input_sftp_base_dir: Rails.application.config.oclc_sftp.data_sync_exception_path)
      super(category: "OclcDataSyncException")
      @input_sftp_base_dir = input_sftp_base_dir
      @file_pattern = 'BibExceptionReport.txt$'
      @oclc_sftp = oclc_sftp
    end

    private

    def handle(data_set:)
      data_set.report_time = Time.zone.now.midnight
      oclc_sftp.start do |sftp|
        sftp.dir.foreach(input_sftp_base_dir) do |entry|
          next unless /#{file_pattern}/.match?(entry.name) && date_in_range?(file_name: entry.name)

          Rails.logger.debug { "Found matching pattern in file: #{entry.name}" }
          remote_filename = File.join(input_sftp_base_dir, entry.name)
          # ascii-8bit required for download! to succeed
          temp_file = Tempfile.new(encoding: 'ascii-8bit')
          sftp.download!(remote_filename, temp_file)
          DataSyncExceptionFile.new(temp_file:).process
        end
      end
      data_set
    end

    def date_in_range?(file_name:)
      file_date_str = file_name.match(/.IN.BIB.D(\d{8})/).captures.first
      file_date = Time.zone.parse(file_date_str)
      today = Time.now.utc
      file_date.between?(today - 7.days, today)
    end
  end
end
