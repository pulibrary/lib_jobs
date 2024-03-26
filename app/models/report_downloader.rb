# frozen_string_literal: true

module Oclc
  class ReportDownloader
    attr_reader :input_sftp_base_dir, :file_pattern, :oclc_sftp, :process_class, :recent
    def initialize(oclc_sftp: OclcSftp.new, file_pattern:, process_class:, input_sftp_base_dir:, recent:)
      @input_sftp_base_dir = input_sftp_base_dir
      @file_pattern = file_pattern
      @oclc_sftp = oclc_sftp
      @process_class = process_class
      @recent = recent
    end

    def run
      working_file_names = []
      oclc_sftp.start do |sftp|
        sftp.dir.foreach(input_sftp_base_dir) do |entry|
          next unless /#{file_pattern}/.match?(entry.name) && date_in_range?(file_name: entry.name)

          Rails.logger.debug { "Found matching pattern in file: #{entry.name}" }
          remote_filename = File.join(input_sftp_base_dir, entry.name)
          # ascii-8bit required for download! to succeed
          temp_file = Tempfile.new(encoding: 'ascii-8bit')
          sftp.download!(remote_filename, temp_file)
          working_file_names << process(temp_file)
        end
      end
      working_file_names
    end

    def date_in_range?(file_name:)
      return true unless recent
      file_date_str = file_name.match(/.IN.BIB.D(\d{8})/).captures.first
      file_date = Time.zone.parse(file_date_str)
      today = Time.now.utc
      file_date.between?(today - 7.days, today)
    end

    def process(temp_file)
      process_class.new(temp_file:).process
    end
  end
end
