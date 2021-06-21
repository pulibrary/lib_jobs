# frozen_string_literal: true
module AlmaInvoiceStatus
  class AlmaXml
    attr_reader :invoices
    def initialize(invoices:)
      @invoices = invoices
    end

    def build
      Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
        xml['xb'].payment_confirmation_data('xmlns:xb' => 'http://com/exlibris/repository/acq/xmlbeans') do
          xml['xb'].invoice_list do
            invoices.each do |invoice_id, info|
              build_invoice(xml: xml, invoice_id: invoice_id, info: info)
            end
          end
        end
      end.to_xml
    end

    private

    def build_invoice(xml:, invoice_id:, info:)
      xml['xb'].invoice do
        xml['xb'].unique_identifier invoice_id
        xml['xb'].payment_status info[:payment_status]
        xml['xb'].invoice_date info[:invoice_date]
        xml['xb'].payment_voucher_date info[:payment_date]
        xml['xb'].payment_voucher_number info[:voucher_id]
        xml['xb'].payment_note info[:message]
        xml['xb'].voucher_amount do
          xml['xb'].currency info[:currency]
          xml['xb'].sum info[:payment_amount]
        end
      end
    end
  end
end
