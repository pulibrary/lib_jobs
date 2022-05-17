# frozen_string_literal: true

module PeoplesoftBursar
  class CreditReport < Report
    attr_reader :sftp_locations, :alma_sftp, :file_pattern, :input_ftp_base_dir

    AMERICAN_DATE = "%m/%d/%Y %H:%M:%S %Z"

    def initialize(input_ftp_base_dir: Rails.application.config.alma_ftp.bursar_report_path, file_pattern: '\.xml$', alma_sftp: AlmaSftp.new, list: nil)
      super(input_ftp_base_dir: input_ftp_base_dir, file_pattern: file_pattern, alma_sftp: alma_sftp, list: list)
    end

    def subject_line
      'Library Credit Feed'
    end

    private

    def parse_list(data)
      doc = Nokogiri::XML(data)
      list = []
      doc.xpath('//xb:userExportedFineFeesList').each do |patron|
        user_id = patron.at_xpath('xb:user/xb:value').text
        patron.xpath('xb:finefeeList/xb:userFineFee').each do |fine|
          list << Credit.new(patron_id: user_id,
                             amount: BigDecimal(fine.at_xpath('xb:compositeSum/xb:sum').text),
                             date: DateTime.strptime(fine.at_xpath('xb:lastTransactionDate').text, AMERICAN_DATE))
        end
      end
      list
    end
  end
end
