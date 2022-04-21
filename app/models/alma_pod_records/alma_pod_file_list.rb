# frozen_string_literal: true
module AlmaPodRecords
  class AlmaPodFileList
    attr_reader :documents

    def initialize(input_ftp_base_dir: Rails.application.config.alma_ftp.pod_output_path, file_pattern: '\.tar\.gz$', alma_sftp: AlmaSftp.new, documents: nil, since: 7.days.ago)
      @input_ftp_base_dir = input_ftp_base_dir
      @file_pattern = file_pattern
      @alma_sftp = alma_sftp
      @since = since
      @sftp_locations = []
      @documents = documents || download_files
    end

    private

    def download_files
      documents = []
      @alma_sftp.start do |sftp|
        sftp.dir.foreach(@input_ftp_base_dir) do |entry|
          next unless /#{@file_pattern}/.match?(entry.name)
          next unless entry.attributes.mtime > @since.to_time.to_i
          Rails.logger.info "Downloading POD file #{entry.name}"
          filename = File.join(@input_ftp_base_dir, entry.name)
          decompressed_files = Tarball.new(sftp.file.open(filename)).contents
          documents.concat(decompressed_files)
        end
      end
      documents
    end
  end
end
