# frozen_string_literal: true

module Oclc
  class NewlyCatalogedJob < LibJob
    attr_reader :oclc_sftp, :input_sftp_base_dir, :file_pattern
    def initialize(oclc_sftp: OclcSftp.new,
                   input_sftp_base_dir: Rails.application.config.oclc_sftp.lc_newly_cataloged_path,
                   file_pattern: 'MZallDLC.1.mrc$')
      super(category: "Oclc")
      @oclc_sftp = oclc_sftp
      @input_sftp_base_dir = input_sftp_base_dir
      @file_pattern = file_pattern
    end

    private

    def handle(data_set:)
      oclc_sftp.start do |sftp|
        sftp.dir.foreach(input_sftp_base_dir) do |entry|
          next unless /#{file_pattern}/.match?(entry.name)

          Rails.logger.debug { "Found matching pattern in file: #{entry.name}" }
          remote_filename = File.join(input_sftp_base_dir, entry.name)
          temp_file = Tempfile.new(encoding: 'UTF-8')
          sftp.download!(remote_filename, temp_file)
          NewlyCatalogedFile.new(temp_file:).process
        end
      end
      data_set
    end
  end
end
