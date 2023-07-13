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
          filename = File.join(input_sftp_base_dir, entry.name)
          # data is a string of Marc
          data = sftp.download!(filename)
          NewlyCatalogedFile.new(data:).process
        end
      end
      data_set
    end
  end
end
