# frozen_string_literal: true
require 'rails_helper'

RSpec.describe AlmaInvoiceStatus::AlmaXml, type: :model do
  subject(:alma_xml) do
    described_class.new(invoices: { '9999999999999999' => invoice1, '9999889999999999' => invoice2, '999779999999999' => invoice3 })
  end
  let(:xml_file) { File.new(Rails.root.join('spec', 'fixtures', 'PU_AP_ALMA_INVOICE_DEATILS_example.xml')) }
  let(:invoice1) do
    { currency: "USD", invoice_date: "20210210", message: "", payment_amount: "805.14",
      payment_date: "20210611", payment_status: "PAID", voucher_id: "A9999999" }
  end
  let(:invoice2) do
    { currency: "USD", invoice_date: "20210329", message: "", payment_amount: "500",
      payment_date: "20210602", payment_status: "PAID", voucher_id: "A9999988" }
  end
  let(:invoice3) do
    { currency: "USD", invoice_date: "20210430", message: "", payment_amount: "70.6",
      payment_date: "20210602", payment_status: "PAID", voucher_id: "A9999977" }
  end

  describe "#invoices" do
    it "parses invoices" do
      expect(alma_xml.build).to eq(File.new(Rails.root.join('spec', 'fixtures', 'alma_status_query_output.xml')).read)
    end
  end
end
