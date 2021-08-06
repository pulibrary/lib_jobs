# frozen_string_literal: true
# access alma xml fund list and make it accessible for processing
module PeoplesoftVoucher
  class AlmaXmlFundList
    attr_reader :fund_list

    delegate :select, :count, :each_with_index, :blank?, to: :fund_list

    def initialize(line_item:)
      @fund_list = parse_fund_list(line_item)
    end

    def total_local_amount
      @total_local ||=
        begin
            total = BigDecimal('0')
            fund_list.each do |fund|
              amount = BigDecimal(fund[:usd_amount])
              total += amount
            end
            total
          end
    end

    def total_local_amount_str
      @total_local_str ||= format("%.2f", total_local_amount)
      @total_local_str
    end

    def total_original_amount
      total = BigDecimal('0')
      fund_list.each do |fund|
        amount = BigDecimal(fund[:original_amount])
        total += amount
      end
      total
    end

    def currency_codes
      codes = []
      fund_list.each do |fund|
        codes << fund[:original_currency]
      end
      codes
    end

    private

    def parse_fund_list(line_item)
      fund_list = []
      line_item.xpath('xmlns:fund_info_list/xmlns:fund_info').each do |fund|
        hash = {}
        hash[:original_amount] = fund.at_xpath('xmlns:amount/xmlns:sum').text
        hash[:original_currency] = fund.at_xpath('xmlns:amount/xmlns:currency').text
        usd_amount = fund.at_xpath('xmlns:local_amount/xmlns:sum').text
        hash[:usd_amount] = format_usd_amount(usd_amount)
        hash = process_chartstring(chartstring: fund.at_xpath('xmlns:external_id'), hash: hash)
        hash[:ledger] = fund.at_xpath('xmlns:ledger_code').text
        hash[:fiscal_period] = fund.at_xpath('xmlns:fiscal_period').text
        fund_list << hash
      end
      fund_list
    end

    def format_usd_amount(amount_string)
      case amount_string
      when /^[0-9]+\.[0-9]{2}$/
        amount_string
      when /^[0-9]+\.[0-9]$/
        amount_string + '0'
      when /^[0-9]+$/
        amount_string + '.00'
      end
    end

    def process_chartstring(chartstring:, hash:)
      hash[:chartstring] = chartstring
      if chartstring.blank?
        hash[:prime_fund] = nil
        hash[:prime_dept] = nil
        hash[:prime_program] = nil
      else
        chartstring = chartstring.text
        string_parts = chartstring.split('|')
        hash[:prime_dept] = string_parts[0]
        hash[:prime_fund] = string_parts[1]
        hash[:prime_program] = string_parts[2]
      end
      hash
    end
  end
end
