# frozen_string_literal: true

module Shared
  # This class is responsible for matching and downloading files from a remote sftp server to local temp files
  # It returns an array of temp file paths
  class ReportDownloader
    Context = Data.define(:sftp, :file_pattern, :process_class, :input_sftp_base_dir, :recent, :date_file_pattern) do
      def initialize(sftp: OclcSftp.new, recent: false, date_file_pattern: '.IN.BIB.D(\d{8})', **) = super
    end

    Report = Data.define(:local_filenames, :remote_filenames)

    def run(context)
      local_filenames = []
      remote_filenames = []
      context.sftp.start do |sftp_conn|
        sftp_conn.dir.foreach(context.input_sftp_base_dir) do |entry|
          next unless valid?(entry, context)

          Rails.logger.debug { "Found matching pattern in file: #{entry.name}" }
          remote_filename = File.join(context.input_sftp_base_dir, entry.name)
          # ascii-8bit required for download! to succeed
          temp_file = Tempfile.new(encoding: 'ascii-8bit')
          sftp_conn.download!(remote_filename, temp_file)
          local_filenames << process(temp_file, context.process_class)
          remote_filenames << remote_filename
        end
      end
      Report.new(local_filenames: local_filenames.flatten.compact, remote_filenames: remote_filenames.flatten)
    end

    private

    def valid?(entry, context)
      return false if /\.processed$/.match?(entry.name)

      /#{context.file_pattern}/.match?(entry.name) && date_in_range?(file_name: entry.name, recent: context.recent, date_file_pattern: context.date_file_pattern)
    end

    def date_in_range?(file_name:, recent:, date_file_pattern:)
      return true unless recent

      file_date_str = file_name.match(/#{date_file_pattern}/).captures.first
      file_date = Time.zone.parse(file_date_str)
      today = Time.now.utc
      file_date.between?(today - 7.days, today)
    rescue NoMethodError
      Rails.logger.warn("Tried to find date in file: #{file_name} using matching pattern: #{date_file_pattern} and did not find a date")
      false
    end

    def process(temp_file, process_class)
      process_class.new(temp_file:).process
    end
  end
end
