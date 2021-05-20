# frozen_string_literal: true
require "rails_helper"

RSpec.describe FinanceMailer, type: :mailer do
  let(:alma_xml_invoice_list) { instance_double("AlmaXMLInvoiceList", errors: errors, error_invoices: error_invoices, valid_invoices: valid_invoices, empty?: false) }
  let(:errors) { [] }
  let(:error_invoices) { [] }
  let(:valid_invoices) do
    [instance_double("AlmaXmlInvoice", errors: [], invoice_date: "2021-12-25", id: 'invoice11', vendor_id: '123', vendor_code: "ABC", total_invoice_amount: '150.00',
                                       invoice_currency: 'USD', invoice_local_amount_total: '150.00', voucher_id: 'voucher11'),
     instance_double("AlmaXmlInvoice", errors: [], invoice_date: "2021-12-25", id: 'invoice12', vendor_id: '456', vendor_code: "DEF", total_invoice_amount: '170.00',
                                       invoice_currency: 'EUR', invoice_local_amount_total: '204.37', voucher_id: 'voucher12')]
  end
  let(:mail) { described_class.report(alma_xml_invoice_list: alma_xml_invoice_list) }

  before do
    allow(alma_xml_invoice_list).to receive(:status_report).and_return("The csv status report")
  end

  it "renders the headers" do
    expect(mail.subject).to eq("Alma to Peoplesoft Voucher Feed Results")
    expect(mail.to).to eq(["cac9@princeton.edu", "mzelesky@princeton.edu", "pdiskin@princeton.edu"])
    expect(mail.from).to eq(["lib-jobs@princeton.edu"])
  end

  it "renders the body" do
    expect(mail.html_part.body.encoded).to include("Alma to Peoplesoft Voucher Feed Results")
    expect(mail.html_part.body.encoded).to include("<h2>No errors were found with the invoices</h2>")
    expect(mail.html_part.body.encoded).to include("<tr><th>Lib Vendor Invoice Date</th><th>Invoice No</th><th>Vendor Code</th><th>Vendor Id</th><th>Invoice Amount</th>"\
                                                   "<th>Invoice Curency</th><th>Local Amount</th><th>Voucher ID</th></tr>")
    expect(mail.html_part.body.encoded).to include("<tr><td>2021-12-25</td><td>invoice11</td><td>ABC</td><td>123</td><td>150.00</td><td>USD</td><td>150.00</td><td>voucher11</td></tr>")
    expect(mail.html_part.body.encoded).to include("<tr><td>2021-12-25</td><td>invoice12</td><td>DEF</td><td>456</td><td>170.00</td><td>EUR</td><td>204.37</td><td>voucher12</td></tr>")
    expect(mail.text_part.body.encoded).to include("Alma to Peoplesoft Voucher Feed Results")
    expect(mail.text_part.body.encoded).to include("No errors were found with the invoices")
    expect(mail.text_part.body.encoded).to include("The csv status report")
  end

  context "with errors" do
    let(:errors) { ["error"] }
    let(:error_invoices) do
      [instance_double("AlmaXmlInvoice", errors: ["Bad Invoice"], invoice_date: "2021-12-25", id: 'invoice1', vendor_id: '123', vendor_code: 'ABC', total_invoice_amount: '150.00',
                                         invoice_currency: 'USD', invoice_local_amount_total: '150.00', voucher_id: 'voucher1'),
       instance_double("AlmaXmlInvoice", errors: ["Bad Invoice", "Bad Line Item"], invoice_date: "2021-12-25", id: 'invoice2', vendor_id: '345', vendor_code: 'DEF', total_invoice_amount: '170.00',
                                         invoice_currency: 'EUR', invoice_local_amount_total: '204.37', voucher_id: 'voucher2')]
    end

    before do
      allow(alma_xml_invoice_list).to receive(:status_report).with(cvs_invoices: error_invoices).and_return("The csv error report")
    end

    it "renders the errors in the body" do
      expect(mail.html_part.body.encoded).to include("Alma to Peoplesoft Voucher Feed Results")
      expect(mail.html_part.body.encoded).to include("<h2>Errors</h2>")
      expect(mail.html_part.body.encoded).to include("<tr><th>Lib Vendor Invoice Date</th><th>Invoice No</th><th>Vendor Code</th><th>Vendor Id</th><th>Invoice Amount</th><th>Invoice Curency</th>"\
                                                     "<th>Local Amount</th><th>Voucher ID</th><th>Errors</th></tr>")
      expect(mail.html_part.body.encoded).to include("<tr><td>2021-12-25</td><td>invoice1</td><td>ABC</td><td>123</td><td>150.00</td><td>USD</td><td>150.00</td><td>voucher1</td>"\
                                                     "<td>Bad Invoice</td></tr>")
      expect(mail.html_part.body.encoded).to include("<tr><td>2021-12-25</td><td>invoice2</td><td>DEF</td><td>345</td><td>170.00</td><td>EUR</td><td>204.37</td><td>voucher2</td>"\
                                                     "<td>Bad Invoice, Bad Line Item</td></tr>")
      expect(mail.text_part.body.encoded).to include("Alma to Peoplesoft Voucher Feed Results")
      expect(mail.text_part.body.encoded).to include("Errors")
      expect(mail.text_part.body.encoded).to include("The csv error report")
    end
  end

  context "without invoices" do
    let(:alma_xml_invoice_list) { instance_double("AlmaXMLInvoiceList", empty?: true, errors: []) }

    it "renders the body" do
      expect(mail.html_part.body.encoded).to include("Alma to Peoplesoft Voucher Feed Results")
      expect(mail.html_part.body.encoded).to include("<h2>No errors were found with the invoices</h2>")
      expect(mail.html_part.body.encoded).to include("<h2>No invoices available to process</h2>")
      expect(mail.text_part.body.encoded).to include("Alma to Peoplesoft Voucher Feed Results")
      expect(mail.text_part.body.encoded).to include("No errors were found with the invoices")
      expect(mail.text_part.body.encoded).to include("No invoices available to process")
    end
  end
end
