# frozen_string_literal: true
class FinanceMailer < ApplicationMailer
  def report(alma_xml_invoice_list:)
    @alma_xml_invoice_list = alma_xml_invoice_list
    mail(to: "cac9@princeton.edu, mzelesky@princeton.edu, pdiskin@princeton.edu", subject: 'Alma to Peoplesoft Voucher Feed Results')
  end
end
