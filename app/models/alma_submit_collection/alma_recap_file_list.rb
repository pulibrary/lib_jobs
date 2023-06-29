# frozen_string_literal: true
module AlmaSubmitCollection
  class AlmaRecapFileList
    attr_reader :files

    def initialize(input_ftp_base_dir: Rails.application.config.alma_ftp.alma_recap_output_path, file_pattern: '\.tar\.gz$', alma_sftp: AlmaSftp.new, files: nil)
      @input_ftp_base_dir = input_ftp_base_dir
      @file_pattern = file_pattern
      @alma_sftp = alma_sftp
      @sftp_locations = []
      @files = files || compile_file_list
    end

    def download_and_decompress_file(filename)
      decompressed_files = []
      @alma_sftp.start do |sftp|
        Rails.logger.info "Downloading Alma Recap file #{filename}"
        full_filename = File.join(@input_ftp_base_dir, filename)
        decompressed_files.concat(Tarball.new(sftp.file.open(full_filename)).contents)
      end
      decompressed_files
    end

    private

    def compile_file_list
      files = []
      @alma_sftp.start do |sftp|
        sftp.dir.foreach(@input_ftp_base_dir) do |entry|
          next unless /#{@file_pattern}/.match?(entry.name)
          next if entry.attributes.size.zero?
          files << entry.name
        end
      end
      files
    end
  end
end
