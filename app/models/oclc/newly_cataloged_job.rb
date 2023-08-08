# frozen_string_literal: true

module Oclc
  class NewlyCatalogedJob < LibJob
    attr_reader :report_downloader, :selectors_config
    def initialize(report_downloader: Oclc::ReportDownloader.new(file_pattern: 'MZallDLC.1.mrc$',
                                                                 process_class: Oclc::NewlyCatalogedFile,
                                                                 input_sftp_base_dir: Rails.application.config.oclc_sftp.lc_newly_cataloged_path,
                                                                 recent: false),
                   selectors_config: Rails.application.config.newly_cataloged.selectors)
      super(category: "Oclc")
      @report_downloader = report_downloader
      @selectors_config = selectors_config
    end

    private

    def handle(data_set:)
      create_csvs_for_selectors

      report_downloader.run

      data_set
    end

    def create_csvs_for_selectors
      selectors_config.each do |selector_config|
        selector_csv = SelectorCSV.new(selector_config:)
        selector_csv.create
      end
    end
  end
end
