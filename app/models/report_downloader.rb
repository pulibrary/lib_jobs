# frozen_string_literal: true
# This class is responsible for matching and downloading files from a remote sftp server to local temp files
# It returns an array of temp file paths
class ReportDownloader
  attr_reader :input_sftp_base_dir, :file_pattern, :sftp, :process_class, :recent, :date_file_pattern, :remote_filenames
  # TODO: Use an object so we don't have to use as many parameters
  # rubocop:disable Metrics/ParameterLists
  def initialize(sftp: OclcSftp.new, file_pattern:, process_class:,
                 input_sftp_base_dir:, recent: false, date_file_pattern: '.IN.BIB.D(\d{8})')
    @input_sftp_base_dir = input_sftp_base_dir
    @file_pattern = file_pattern
    @sftp = sftp
    @process_class = process_class
    @recent = recent
    @date_file_pattern = date_file_pattern
    @remote_filenames = []
  end
  # rubocop:enable Metrics/ParameterLists

  def run
    working_file_names = []
    sftp.start do |sftp_conn|
      sftp_conn.dir.foreach(input_sftp_base_dir) do |entry|
        next if /\.processed$/.match?(entry.name)
        next unless /#{file_pattern}/.match?(entry.name) && date_in_range?(file_name: entry.name)

        Rails.logger.debug { "Found matching pattern in file: #{entry.name}" }
        remote_filename = File.join(input_sftp_base_dir, entry.name)
        # ascii-8bit required for download! to succeed
        temp_file = Tempfile.new(encoding: 'ascii-8bit')
        sftp_conn.download!(remote_filename, temp_file)
        working_file_names << process(temp_file)
        remote_filenames << remote_filename
      end
    end
    working_file_names.compact
  end

  def date_in_range?(file_name:)
    return true unless recent
    file_date_str = file_name.match(/#{date_file_pattern}/).captures.first
    file_date = Time.zone.parse(file_date_str)
    today = Time.now.utc
    file_date.between?(today - 7.days, today)
  rescue NoMethodError
    Rails.logger.warn("Tried to find date in file: #{file_name} using matching pattern: #{date_file_pattern} and did not find a date")
    false
  end

  def process(temp_file)
    process_class.new(temp_file:).process
  end
end
