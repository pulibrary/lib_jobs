# frozen_string_literal: true
require 'csv'

module PeoplesoftBursar
  class FineReport < Report
    def initialize(input_ftp_base_dir: Rails.application.config.alma_ftp.bursar_report_path, file_pattern: '\.csv$', alma_sftp: AlmaSftp.new, list: nil)
      super(input_ftp_base_dir: input_ftp_base_dir, file_pattern: file_pattern, alma_sftp: alma_sftp, list: list)
      @report_type = 'Payment'
    end

    private

    def parse_list(data)
      list = []
      CSV.parse(data.delete_prefix("\uFEFF"), headers: true) do |row|
        list << Fine.new(amount: BigDecimal(row['Transaction Amount']),
                         patron_id: row['Primary Identifier'],
                         fine_id: row['Fine Fee Id'],
                         fine_type: row['Fine Fee Type'],
                         date: DateTime.parse(row['Transaction Date']))
      end
      list
    end
  end
end
