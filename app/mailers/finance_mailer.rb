# frozen_string_literal: true
class FinanceMailer < ApplicationMailer
  def report(alma_xml_invoice_list:)
    @alma_xml_invoice_list = alma_xml_invoice_list
    mail(to: LibJobs.config[:voucher_feed_recipients], subject: 'Alma to Peoplesoft Voucher Feed Results')
  end

  def bursar_report(report:)
    @report = report
    mail_to = if !report.list.empty?
                LibJobs.config[:peoplesoft_bursar_recipients]
              else
                LibJobs.config[:peoplesoft_bursar_no_report_recipients]
              end
    mail(to: mail_to, subject: report.subject_line)
  end
end
