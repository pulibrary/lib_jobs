# frozen_string_literal: true

module Oclc
  class DataSyncProcessingJob < LibJob
    attr_reader :report_downloader

    def initialize(report_downloader: Oclc::ReportDownloader.new(file_pattern: 'BibProcessingReport.txt$',
                                                                 process_class: Oclc::DataSyncProcessingFile,
                                                                 input_sftp_base_dir: Rails.application.config.oclc_sftp.data_sync_report_path,
                                                                 recent: true))
      super(category: "OclcBibProcessingReport")
      @report_downloader = report_downloader
    end

    private

    def handle(data_set:)
      data_set.report_time = Time.zone.now.midnight

      report_downloader.run

      data_set
    end
  end
end
