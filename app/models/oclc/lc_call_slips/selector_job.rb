# frozen_string_literal: true

module Oclc
  module LcCallSlips
    class SelectorJob < LcCallSlipJob
      attr_reader :report_downloader, :selectors_config
      def initialize(report_downloader: ReportDownloader.new(file_pattern: Rails.application.config.oclc_sftp.lc_call_slips_file_pattern,
                                                             process_class: Oclc::LcCallSlips::SelectorFile,
                                                             input_sftp_base_dir: Rails.application.config.oclc_sftp.lc_call_slips_path,
                                                             recent: false),
                     selectors_config: Rails.application.config.lc_call_slips.selectors)
        super(category: "Oclc:LcCallSlips")
        @report_downloader = report_downloader
        @selectors_config = selectors_config
      end

      private

      def handle(data_set:)
        csvs_created = create_csvs_for_selectors
        report_downloader.run
        email_csvs_to_selectors
        data_set.data = "Files created and emailed to selectors: #{csvs_created.join(', ')}"
        data_set
      end

      def email_csvs_to_selectors
        selectors_config.each do |selector_config|
          selector_csv = SelectorCSV.new(selector_config:)
          selector = Selector.new(selector_config:)
          LcCallSlipsMailer.report(selector:, file_path: selector_csv.file_path).deliver
        end
      end

      def create_csvs_for_selectors
        csvs_created = []
        selectors_config.each do |selector_config|
          selector_csv = SelectorCSV.new(selector_config:)
          selector_csv.create
          csvs_created << selector_csv.file_path
        end
        csvs_created
      end
    end
  end
end
