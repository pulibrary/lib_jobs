# frozen_string_literal: true
module AlmaSubmitCollection
  # This class is responsible for interacting
  # with SubmitCollection-related files on the
  # sftp server
  class AlmaRecapFileList
    attr_reader :files

    def initialize(input_sftp_base_dir: Rails.application.config.alma_sftp.alma_recap_output_path, file_pattern: '\.tar\.gz$', alma_sftp: AlmaSftp.new, files: nil)
      @input_sftp_base_dir = input_sftp_base_dir
      @file_pattern = file_pattern
      @alma_sftp = alma_sftp
      @sftp_locations = []
      @files = if Flipflop.meter_files_sent_to_recap?
                 files || compile_metered_file_list
               else
                 files || compile_file_list
               end
    end

    # @return [Array<StringIO>]
    # Won't this be the contents of *all* the decompressed files? Maybe the source of our memory issues?
    def file_contents
      @file_contents ||= @files.map { |filename| download_and_decompress_file(filename) }
                               .flatten
    end

    # @return [Array<StringIO>]
    def download_and_decompress_file(filename)
      decompressed_files = []
      @alma_sftp.start do |sftp|
        Rails.logger.info "Downloading Alma Recap file #{filename}"
        decompressed_files.concat(Tarball.new(sftp.file.open(full_filename(filename))).contents)
      end
      decompressed_files
    end

    def mark_files_as_processed
      @alma_sftp.start do |sftp|
        files.each do |filename|
          sftp.rename(full_filename(filename), "#{full_filename(filename)}.processed")
        end
      end
    end

    def compile_metered_file_list
      files = []
      all_matching_files = []
      @alma_sftp.start do |sftp|
        all_matching_files = sftp.dir.glob(@input_sftp_base_dir, '*[^delete].xml.tar.gz')
      end
      files_oldest_to_newest = all_matching_files.sort_by { |entry| entry.attributes.mtime }
      files_oldest_to_newest.take(Rails.application.config.alma_sftp.max_files_for_recap).each do |entry|
        next unless /#{@file_pattern}/.match?(entry.name)
        # rubocop:disable Style/ZeroLengthPredicate -- entry.attributes is an Net::SFTP::Protocol::V01::Attributes, not an array
        next if entry.attributes.size.zero?
        # rubocop:enable Style/ZeroLengthPredicate
        files << entry.name
      end
      files
    end

    private

    def compile_file_list
      files = []
      @alma_sftp.start do |sftp|
        sftp.dir.foreach(@input_sftp_base_dir) do |entry|
          next unless /#{@file_pattern}/.match?(entry.name)
          # rubocop:disable Style/ZeroLengthPredicate -- entry.attributes is an Net::SFTP::Protocol::V01::Attributes, not an array
          next if entry.attributes.size.zero?
          # rubocop:enable Style/ZeroLengthPredicate
          files << entry.name
        end
      end
      files
    end

    def full_filename(filename)
      File.join(@input_sftp_base_dir, filename)
    end
  end
end
