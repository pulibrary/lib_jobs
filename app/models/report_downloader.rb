# frozen_string_literal: true
# This class is responsible for matching and downloading files from a remote sftp server to local temp files
# It returns an array of temp file paths
class ReportDownloader
  attr_reader :sftp, :file_pattern, :input_sftp_base_dir, :process_class, :remote_filenames
  # sftp should be an instance of an Sftp class - e.g. OclcSftp.new, GobiFtp.new
  # file_pattern is a string that will be used as regex to match files against
  # input_sftp_base_dir is the directory to check for files in
  def initialize(sftp:, file_pattern:, input_sftp_base_dir:, process_class:)
    @sftp = sftp
    @file_pattern = file_pattern
    @input_sftp_base_dir = input_sftp_base_dir
    @process_class = process_class
    @remote_filenames = []
  end

  def run
    working_file_names = []
    sftp.start do |sftp_conn|
      sftp_conn.dir.foreach(input_sftp_base_dir) do |entry|
        next if /\.processed$/.match?(entry.name)
        next unless /#{file_pattern}/.match?(entry.name)

        Rails.logger.debug { "Found matching pattern in file: #{entry.name}" }
        remote_filename = File.join(input_sftp_base_dir, entry.name)
        # ascii-8bit required for download! to succeed
        temp_file = Tempfile.new(encoding: 'ascii-8bit')
        sftp_conn.download!(remote_filename, temp_file)
        working_file_names << process(temp_file)
        remote_filenames << remote_filename
      end
    end
    working_file_names
  end

  def process(temp_file)
    process_class.new(temp_file:).process
  end
end
