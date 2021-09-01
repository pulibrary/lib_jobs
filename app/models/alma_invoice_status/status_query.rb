# frozen_string_literal: true
module AlmaInvoiceStatus
  class StatusQuery
    attr_reader :doc

    def initialize(xml_io:)
      @doc = Nokogiri::XML(xml_io)
    end

    def invoices
      invoices = {}
      doc.xpath('//row').each do |row|
        invoice_id = safe_lookup(row, 'INVOICE_ID')
        invoices[invoice_id] = convert_row(row)
      end
      invoices
    end

    private

    def convert_row(row)
      { payment_status: payment_status(row),
        invoice_date: safe_lookup(row, 'INVOICE_DATE'),
        payment_date: safe_lookup(row, 'PAYMENT_VOUCHER_DATE'),
        voucher_id: safe_lookup(row, 'VOUCHER_ID'),
        currency: safe_lookup(row, 'CURRENCY_PYMNT'),
        payment_amount: safe_lookup(row, 'PAID_AMT'),
        message: safe_lookup(row, 'PYMNT_MESSAGE') }
    end

    def payment_status(row)
      payment_status = safe_lookup(row, 'PYMNT_SELCT_STATUS')
      payment_status = payment_status.upcase
      payment_status = 'REJECTED' unless payment_status == 'PAID'
      payment_status
    end

    def safe_lookup(row, key)
      row.at_xpath(key)&.text || ''
    end
  end
end
