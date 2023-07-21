# frozen_string_literal: true
module AlmaSubmitCollection
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
      Tarball.new(download_file(filename)).contents
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

    def download_file(filename)
      @alma_sftp.start do |sftp|
        Rails.logger.info "Downloading Alma Recap file #{filename}"
        full_filename = File.join(@input_sftp_base_dir, filename)
        contents = sftp.file.open(full_filename)
        sftp.rename(full_filename, "#{full_filename}.processed")
        contents
      end
    end
  end
end
