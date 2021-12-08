# frozen_string_literal: true
# access an alma xml invoice and make the invoice information accessible for processing
# rubocop:disable Metrics/ClassLength
module PeoplesoftVoucher
  class AlmaXmlInvoice
    attr_reader :xml_invoice, :line_items, :errors

    def initialize(xml_invoice:)
      @xml_invoice = xml_invoice
      @line_items = parse_alma_line_items
      validate_invoice
    end

    def id
      @invoice_id ||= xml_invoice.at_xpath('xmlns:invoice_number').text.strip
    end

    def voucher_id
      @voucher_id ||= begin
                        id_number_string = unique_identifier[2..-6]
                        id = id_number_string.to_i
                        "A#{id.to_s(36).rjust(7, '0')}".upcase
                      end
      @voucher_id
    end

    def valid?
      errors.empty?
    end

    def payment_message
      currency_codes = currency_codes_for_invoice
      payment_message = nil
      if currency_codes.size == 1 && currency_codes.first != 'USD'
        single_code = currency_codes.first
        decimals = original_currency_decimals(single_code)
        payment_message = "Pay #{format("%.#{decimals}f", total_invoice_amount)} in #{single_code}"
      end
      payment_message
    end

    def invoice_local_amount_total
      @invoices_local_amount_total ||= begin
                                        total = BigDecimal('0')
                                        line_items.each do |line_item|
                                          total += line_item[:total_local_amount]
                                        end
                                        total = total.to_s('F')
                                        parts = total.split('.')
                                        num = parts[0]
                                        dec_places = parts[1]
                                        dec_places << '0' while dec_places.size < 2
                                        num + '.' + dec_places
                                      end
    end

    def currency_codes_for_invoice
      currency_codes = []
      line_items.each do |line_item|
        currency_codes += line_item[:fund_list].currency_codes
      end
      currency_codes.uniq
    end

    def unique_identifier
      @unique_identifier ||= xml_invoice.at_xpath('xmlns:unique_identifier')&.text
    end

    def invoice_date
      @invoice_date ||= begin
                        inv_date = xml_invoice.at_xpath('xmlns:invoice_date').text
                        inv_date.gsub(/^([0-9]{2}).([0-9]{2}).([0-9]{4})$/, '\3-\1-\2')
                      end
    end

    def vendor_code
      @vendor_code ||= xml_invoice.at_xpath('xmlns:vendor_code')&.text
    end

    def vendor_id
      @vendor_id ||= xml_invoice.at_xpath('xmlns:vendor_FinancialSys_Code')&.text
    end

    def total_invoice_amount
      @total_invoice_amount ||= xml_invoice.at_xpath('xmlns:invoice_amount/xmlns:sum').text
    end

    def invoice_currency
      @invoice_currency ||= xml_invoice.at_xpath('xmlns:invoice_amount/xmlns:currency').text
    end

    def invoice_create_date
      @inv_create_date ||= begin
                            inv_create_date = xml_invoice.at_xpath('xmlns:invoice_ownered_entity/xmlns:creationDate').text
                            inv_create_date.gsub(/^([0-9]{2}).([0-9]{2}).([0-9]{4})$/, '\3-\1-\2')
                          end
    end

    def vendor_location
      @vendor_location ||= xml_invoice.at_xpath('xmlns:vendor_additional_code')&.text
    end

    private

    def validate_invoice
      @errors = []
      errors << "Invalid vendor_id: vendor_id can not be blank" if vendor_id.blank?
      validate_fund_list_blank_funds
      validate_fund_list_blank_dept
      validate_reporting_code
      validate_invoice_date
    end

    def validate_fund_list_blank_funds
      blank_funds = line_items.select { |line| line[:fund_list].count { |fund| fund[:prime_fund].blank? }.positive? }
      errors << "Line Item Invalid: primary fund can not be blank" if blank_funds.flatten.size.positive?
    end

    def validate_fund_list_blank_dept
      blank_dept = line_items.select { |line| line[:fund_list].count { |fund| fund[:prime_dept].blank? }.positive? }
      errors << "Line Item Invalid: primary department can not be blank" if blank_dept.flatten.size.positive?
    end

    def validate_reporting_code
      reporting_fund_errors = line_items.select do |line|
        line[:reporting_code] =~ /[^0-9]/ || line[:reporting_code].blank?
      end
      errors << "Invalid reporting code: must be numeric and can not be blank" if reporting_fund_errors.size.positive?
    end

    def validate_invoice_date
      parsed_invoice_date = Time.zone.parse(invoice_date)
      current_date = Time.zone.now
      invalid_date = ((current_date - parsed_invoice_date) > (365 * 4).days.to_f) || ((parsed_invoice_date - current_date) > 31.days.to_f)
      errors << "Invalid invoice date: must be between four years old and one month into the future" if invalid_date
    end

    # @returns [Array] of all the line item metadata as a hash
    def parse_alma_line_items
      line_items = []
      xml_invoice.xpath('xmlns:invoice_line_list/xmlns:invoice_line').each do |line_item|
        line_info = parse_alma_line_item(line_item)
        line_items << line_info if line_info[:fund_list].present?
      end
      line_items
    end

    def currency_decimals
      {
        'BHD' => 3,
        'CVE' => 0,
        'JPY' => 0,
        'ISK' => 0,
        'KRW' => 0
      }
    end

    def original_currency_decimals(currency_code)
      decimals = currency_decimals[currency_code]
      decimals || 2
    end

    def get_alma_po_info(line_item)
      hash = {}
      raw_title = line_item.at_xpath('xmlns:po_line_info/xmlns:po_line_title')&.text
      title = raw_title&.unicode_normalize(:nfd) || 'adjustment'
      title = title.encode('ISO-8859-1', invalid: :replace, undef: :replace, replace: '')
      hash[:title] = title[0..253]
      po_line_number = line_item.at_xpath('xmlns:po_line_info/xmlns:po_line_number')&.text
      hash[:po_line_number] = po_line_number || ''
      bib_id = line_item.at_xpath('xmlns:po_line_info/xmlns:mms_record_id')&.text
      hash[:bib_id] = bib_id || ''
      vendor_ref_num = line_item.at_xpath('xmlns:po_line_info/xmlns:vendor_reference_number')&.text
      hash[:vendor_ref_num] = vendor_ref_num || ''
      hash
    end

    ### Reporting code is used for the entire invoice line instead of each payment
    # rubocop:disable Metrics/MethodLength
    def parse_alma_line_item(line_item)
      line_item_hash = {}
      line_item_hash[:inv_line_number] = line_item.at_xpath('xmlns:line_number').text
      line_item_hash[:reporting_code] = line_item.at_xpath('xmlns:reporting_code')&.text
      line_item_hash[:fund_list] = PeoplesoftVoucher::AlmaXmlFundList.new(line_item: line_item)
      line_item_hash[:currencies] = line_item_hash[:fund_list].currency_codes
      line_item_hash[:total_local_amount] = line_item_hash[:fund_list].total_local_amount
      line_item_hash[:total_local_amount_str] = line_item_hash[:fund_list].total_local_amount_str
      line_item_hash[:total_original_amount] = line_item_hash[:fund_list].total_original_amount
      line_item_hash[:inv_line_note] = line_item.at_xpath('xmlns:note')&.text
      po_info = get_alma_po_info(line_item)
      line_item_hash[:title] = po_info[:title]
      line_item_hash[:po_line_number] = po_info[:po_line_number]
      line_item_hash[:vendor_ref_num] = po_info[:vendor_ref_num]
      line_item_hash[:bib_id] = po_info[:bib_id]
      line_item_hash
    end
    # rubocop:enable Metrics/MethodLength
  end
  # rubocop:enable Metrics/ClassLength
end
