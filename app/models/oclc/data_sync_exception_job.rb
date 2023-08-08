# frozen_string_literal: true

module Oclc
  class DataSyncExceptionJob < LibJob
    attr_reader :report_downloader

    def initialize(report_downloader: Oclc::ReportDownloader.new(file_pattern: 'BibExceptionReport.txt$',
                                                                 process_class: Oclc::DataSyncExceptionFile,
                                                                 input_sftp_base_dir: Rails.application.config.oclc_sftp.data_sync_report_path,
                                                                 recent: true))
      super(category: "OclcDataSyncException")
      @report_downloader = report_downloader
    end

    private

    def handle(data_set:)
      data_set.report_time = Time.zone.now.midnight

      report_downloader.run

      data_set
    end

    def date_in_range?(file_name:)
      file_date_str = file_name.match(/.IN.BIB.D(\d{8})/).captures.first
      file_date = Time.zone.parse(file_date_str)
      today = Time.now.utc
      file_date.between?(today - 7.days, today)
    end
  end
end
