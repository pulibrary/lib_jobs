# frozen_string_literal: true
require 'rails_helper'

RSpec.describe AlmaInvoiceStatus::StatusQuery, type: :model do
  subject(:invoice_details) do
    described_class.new(xml_io: xml_file)
  end
  let(:xml_file) { File.new(Rails.root.join('spec', 'fixtures', 'PU_AP_ALMA_INVOICE_DEATILS_example.xml')) }

  describe "#invoices" do
    it "parses invoices" do
      invoices = invoice_details.invoices
      expect(invoices.count).to eq(3)
      expect(invoices['9999999999999999']).to eq({ currency: "USD", invoice_date: "20210210", message: "", payment_amount: "805.14",
                                                   payment_date: "20210611", payment_status: "PAID", voucher_id: "A9999999" })
      expect(invoices['9999889999999999']).to eq({ currency: "USD", invoice_date: "20210329", message: "", payment_amount: "500",
                                                   payment_date: "20210602", payment_status: "PAID", voucher_id: "A9999988" })
      expect(invoices['999779999999999']).to eq({ currency: "USD", invoice_date: "20210430", message: "", payment_amount: "70.6",
                                                  payment_date: "20210602", payment_status: "PAID", voucher_id: "A9999977" })
    end
  end
end
