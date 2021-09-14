# frozen_string_literal: true
require 'rails_helper'

RSpec.describe PeoplesoftVoucher::AlmaXmlInvoice, type: :model do
  subject(:alma_invoice) do
    pin_time_to_valid_invoice_list
    described_class.new(xml_invoice: invoices.first)
  end

  let(:invoices) do
    doc = Nokogiri::XML(xml_file)
    doc.xpath('//xmlns:invoice_list/xmlns:invoice')
  end

  let(:xml_file) { File.new(Rails.root.join('spec', 'fixtures', 'invoice_export_202118300518.xml')) }

  describe "#voucher_id" do
    it "returns the id" do
      expect(alma_invoice.voucher_id).to eq('A0K7QUIS')
    end

    context "invalid invoice" do
      let(:xml_file) { File.new(Rails.root.join('spec', 'fixtures', 'invalid_invoice.xml')) }

      it "returns the id" do
        expect(alma_invoice.voucher_id).to eq('A0K7QUIS')
      end
    end
  end

  describe "#payment_message" do
    it "returns the payment message" do
      expect(alma_invoice.payment_message).to be_nil
    end

    context "invalid invoice" do
      let(:xml_file) { File.new(Rails.root.join('spec', 'fixtures', 'invalid_invoice.xml')) }

      it "returns the payment message" do
        expect(alma_invoice.payment_message).to eq('Pay 1319.05 in GBP')
      end
    end
  end

  describe "#invoice_local_amount_total" do
    it "returns the local amount" do
      expect(alma_invoice.invoice_local_amount_total).to eq('124.94')
    end

    context "invalid invoice" do
      let(:xml_file) { File.new(Rails.root.join('spec', 'fixtures', 'invalid_invoice.xml')) }

      it "returns the local amount" do
        expect(alma_invoice.invoice_local_amount_total).to eq('176.66')
      end
    end
  end

  describe "#currency_codes_for_invoice" do
    it "returns the currency codes" do
      expect(alma_invoice.currency_codes_for_invoice).to eq(["USD"])
    end

    context "invalid invoice" do
      let(:xml_file) { File.new(Rails.root.join('spec', 'fixtures', 'invalid_invoice.xml')) }

      it "returns the currency codes" do
        expect(alma_invoice.currency_codes_for_invoice).to eq(["GBP"])
      end
    end
  end

  describe "#invoice_date" do
    it "returns the invoice date" do
      expect(alma_invoice.invoice_date).to eq('2021-03-30')
    end

    context "invalid invoice" do
      let(:xml_file) { File.new(Rails.root.join('spec', 'fixtures', 'invalid_invoice.xml')) }

      it "returns the invoice date" do
        expect(alma_invoice.invoice_date).to eq('1996-03-30')
      end
    end
  end

  describe "#valid?" do
    it "is valid " do
      expect(alma_invoice.valid?).to be_truthy
    end

    context "invalid invoice" do
      let(:xml_file) { File.new(Rails.root.join('spec', 'fixtures', 'invalid_invoice.xml')) }

      it "is not valid" do
        expect(alma_invoice.valid?).to be_falsey
        expect(alma_invoice.errors).to contain_exactly("Invalid vendor_id: vendor_id can not be blank",
                                                       "Line Item Invalid: primary fund can not be blank",
                                                       "Line Item Invalid: primary department can not be blank",
                                                       "Invalid reporting code: must be numeric and can not be blank",
                                                       "Invalid invoice date: must be between four years old and one month into the future")
      end
    end
  end

  describe "#total_invoice_amount" do
    it "returns the invoice total" do
      expect(alma_invoice.total_invoice_amount).to eq('1319.05')
    end

    context "invalid invoice" do
      let(:xml_file) { File.new(Rails.root.join('spec', 'fixtures', 'invalid_invoice.xml')) }

      it "returns the invoice total" do
        expect(alma_invoice.total_invoice_amount).to eq('1319.05')
      end
    end
  end

  describe "#invoice_currency" do
    it "returns the invoice total" do
      expect(alma_invoice.invoice_currency).to eq('USD')
    end

    context "invalid invoice" do
      let(:xml_file) { File.new(Rails.root.join('spec', 'fixtures', 'invalid_invoice.xml')) }

      it "returns the invoice total" do
        expect(alma_invoice.invoice_currency).to eq('GBP')
      end
    end
  end
end
