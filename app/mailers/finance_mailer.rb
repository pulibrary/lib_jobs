# frozen_string_literal: true
class FinanceMailer < ApplicationMailer
  def report(alma_xml_invoice_list:)
    @alma_xml_invoice_list = alma_xml_invoice_list
    mail(to: "person@example.com", subject: 'Alma to Peoplesoft Voucher Feed Results')
  end
end
