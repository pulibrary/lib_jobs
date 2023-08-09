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
      @files = files || compile_file_list
    end

    # @return [Array<StringIO>]
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

    private

    def compile_file_list
      files = []
      @alma_sftp.start do |sftp|
        sftp.dir.foreach(@input_sftp_base_dir) do |entry|
          next unless /#{@file_pattern}/.match?(entry.name)
          next if entry.attributes.size.zero?
          files << entry.name
        end
      end
      files
    end

    def download_file(filename)
      @alma_sftp.start do |sftp|
        Rails.logger.info "Downloading Alma Recap file #{filename}"
        sftp.file.open(full_filename(filename))
      end
    end

    def full_filename(filename)
      File.join(@input_sftp_base_dir, filename)
    end
  end
end
