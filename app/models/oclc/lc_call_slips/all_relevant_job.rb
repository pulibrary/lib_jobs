# frozen_string_literal: true

module Oclc
  module LcCallSlips
    class AllRelevantJob < LcCallSlipJob
      def initialize(report_downloader: Oclc::ReportDownloader.new(file_pattern: Rails.application.config.oclc_sftp.lc_call_slips_file_pattern,
                                                                   process_class: Oclc::LcCallSlips::AllRelevantFile,
                                                                   input_sftp_base_dir: Rails.application.config.oclc_sftp.lc_call_slips_path,
                                                                   recent: false))
        super(category: "Oclc:LcCallSlipsAll")
        @report_downloader = report_downloader
      end

      def self.all_records_file_path
        date = Time.now.utc.strftime('%Y-%m-%d')
        file_name = "#{date}-newly-cataloged-by-lc-all.csv"
        "#{csv_file_path}#{file_name}"
      end

      def self.csv_file_path
        Rails.application.config.lc_call_slips.selector_csv_path
      end

      private

      def handle(data_set:)
        csv_created = create_csv_with_all_generally_relevant_records
        report_downloader.run
        data_set.data = "File created: #{csv_created}"
        data_set
      end

      def create_csv_with_all_generally_relevant_records
        Dir.mkdir(AllRelevantJob.csv_file_path) unless Dir.exist?(AllRelevantJob.csv_file_path)
        create
      end

      def create
        headers = ['OCLC Number', 'ISBNs', 'LCCNs', 'Author', 'Title', '008 Place Code',
                   'Pub Place', 'Pub Name', 'Pub Date', 'Description', 'Format', 'Languages',
                   'Call Number', 'Subjects', 'Non-Romanized Title']
        CSV.open(AllRelevantJob.all_records_file_path, 'w', encoding: 'bom|utf-8') do |csv|
          csv.to_io.write "\uFEFF" # use CSV#to_io to write BOM directly
          csv << headers
        end
      end
    end
  end
end
