# frozen_string_literal: true
module AlmaPodRecords
  class AlmaPodFileList
    attr_reader :files

    def initialize(input_ftp_base_dir: Rails.application.config.alma_sftp.pod_output_path, file_pattern: '\.tar\.gz$', alma_sftp: AlmaSftp.new, files: nil, since: 7.days.ago)
      @input_ftp_base_dir = input_ftp_base_dir
      @file_pattern = file_pattern
      @alma_sftp = alma_sftp
      @since = since
      @sftp_locations = []
      @files = files || compile_file_list
    end

    def download_and_decompress_file(filename)
      decompressed_files = []
      @alma_sftp.start do |sftp|
        Rails.logger.info "Downloading POD file #{filename}"
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
          next unless entry.attributes.mtime > @since.to_time.to_i
          next if entry.attributes.size.zero?
          files << entry.name
        end
      end
      files
    end
  end
end
