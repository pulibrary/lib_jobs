# frozen_string_literal: true
require 'rails_helper'

RSpec.describe AlmaXmlInvoiceList, type: :model do
  subject(:alma_invoice_list) { described_class.new }

  let(:sftp_entry1) { instance_double("Net::SFTP::Protocol::V01::Name", name: "abc.xml") }
  let(:sftp_entry2) { instance_double("Net::SFTP::Protocol::V01::Name", name: "abc.xml2") }
  let(:sftp_entry3) { instance_double("Net::SFTP::Protocol::V01::Name", name: "123.xml") }
  let(:sftp_session) { instance_double("Net::SFTP::Session", dir: sftp_dir) }
  let(:sftp_dir) { instance_double("Net::SFTP::Operations::Dir") }

  let(:xml_file) { File.new(Rails.root.join('spec', 'fixtures', 'invoice_export_202118300518.xml')) }
  let(:invoice_errors) do
    "Invalid vendor_id: vendor_id can not be blank,"\
    " Line Item Invalid: No fund lists exists," \
    " Line Item Invalid: primary fund can not be blank,"\
    " Line Item Invalid: primary department can not be blank,"\
    " Invalid reporting code: must be numeric and can not be blank"
  end

  before do
    allow(sftp_dir).to receive(:foreach).and_yield(sftp_entry1).and_yield(sftp_entry2)
    # only 1 & 3 should get downloaded
    allow(sftp_session).to receive(:download!).with("/alma/invoices/abc.xml").and_return(Rails.root.join('spec', 'fixtures', 'invoice_export_202118300518.xml').read)
    allow(sftp_session).to receive(:download!).with("/alma/invoices/123.xml").and_return(Rails.root.join('spec', 'fixtures', 'invalid_invoice.xml').read)
    allow(sftp_session).to receive(:rename).with("/alma/invoices/123.xml", "/alma/invoices/123.xml.processed")
    allow(sftp_session).to receive(:rename).with("/alma/invoices/abc.xml", "/alma/invoices/abc.xml.processed")
    allow(Net::SFTP).to receive(:start).and_yield(sftp_session)
  end

  describe "#invoices" do
    it "parses the list " do
      expect(alma_invoice_list.invoices.count).to eq(1)
      expect(sftp_session).to have_received(:download!).with("/alma/invoices/abc.xml")
    end
  end

  describe "#errors" do
    it "has no errors" do
      expect(alma_invoice_list.errors).to be_blank
    end
  end

  describe "#mark_files_as_processed" do
    it "moves the files" do
      alma_invoice_list.mark_files_as_processed
      expect(sftp_session).to have_received(:rename).with("/alma/invoices/abc.xml", "/alma/invoices/abc.xml.processed")
    end
  end

  describe "#onbase_report" do
    it "generates the correct csv" do
      expect(alma_invoice_list.onbase_report).to eq("\"2021-03-30\",\"PO-9999\",\"111222333\",\"1319.05\",\"A1222333\"\n")
    end
  end

  describe "#status_report" do
    it "generates the correct csv" do
      expect(alma_invoice_list.status_report).to eq("Lib Vendor Invoice Date,Invoice No,Vendor Code,Invoice Amount,Invoice Curency,Local Amount,Voucher ID,Errors\n"\
                                                    "2021-03-30,PO-9999,111222333,1319.05,USD,124.94,A1222333,\"\"\n")
    end
  end

  context "invalid invoice" do
    before do
      allow(sftp_dir).to receive(:foreach).and_yield(sftp_entry2).and_yield(sftp_entry3)
    end

    describe "#invoices" do
      it "parses the list " do
        expect(alma_invoice_list.invoices.count).to eq(1)
        expect(sftp_session).to have_received(:download!).with("/alma/invoices/123.xml")
      end
    end

    describe "#errors" do
      it "has the expected errors" do
        expect(alma_invoice_list.errors).to contain_exactly("PO-9999\t1112223334445555\t#{invoice_errors}")
        expect(sftp_session).to have_received(:download!).with("/alma/invoices/123.xml")
      end
    end

    describe "#mark_files_as_processed" do
      it "moves the files" do
        alma_invoice_list.mark_files_as_processed
        expect(sftp_session).to have_received(:rename).with("/alma/invoices/123.xml", "/alma/invoices/123.xml.processed")
      end
    end

    describe "#onbase_report" do
      it "generates the correct csv" do
        expect(alma_invoice_list.onbase_report).to eq("")
      end
    end

    describe "#status_report" do
      it "generates the correct csv" do
        expect(alma_invoice_list.status_report).to eq("Lib Vendor Invoice Date,Invoice No,Vendor Code,Invoice Amount,Invoice Curency,Local Amount,Voucher ID,Errors\n"\
                                                      "2021-03-30,PO-9999,\"\",1319.05,GBP,176.66,A1222333,\"#{invoice_errors}\"\n")
      end
    end
  end

  context "invalid and valid invoices" do
    before do
      allow(sftp_dir).to receive(:foreach).and_yield(sftp_entry1).and_yield(sftp_entry2).and_yield(sftp_entry3)
    end

    describe "#invoices" do
      it "parses the list " do
        expect(alma_invoice_list.invoices.count).to eq(2)
        expect(sftp_session).to have_received(:download!).with("/alma/invoices/123.xml")
        expect(sftp_session).to have_received(:download!).with("/alma/invoices/abc.xml")
      end
    end

    describe "#errors" do
      it "has the expected errors" do
        expect(alma_invoice_list.errors).to contain_exactly("PO-9999\t1112223334445555\t#{invoice_errors}")
        expect(sftp_session).to have_received(:download!).with("/alma/invoices/123.xml")
      end
    end

    describe "#mark_files_as_processed" do
      it "moves the files" do
        alma_invoice_list.mark_files_as_processed
        expect(sftp_session).to have_received(:rename).with("/alma/invoices/123.xml", "/alma/invoices/123.xml.processed")
        expect(sftp_session).to have_received(:rename).with("/alma/invoices/abc.xml", "/alma/invoices/abc.xml.processed")
      end
    end

    describe "#onbase_report" do
      it "generates the correct csv" do
        expect(alma_invoice_list.onbase_report).to eq("\"2021-03-30\",\"PO-9999\",\"111222333\",\"1319.05\",\"A1222333\"\n")
      end
    end

    describe "#status_report" do
      it "generates the correct csv" do
        expect(alma_invoice_list.status_report).to eq("Lib Vendor Invoice Date,Invoice No,Vendor Code,Invoice Amount,Invoice Curency,Local Amount,Voucher ID,Errors\n"\
                                                      "2021-03-30,PO-9999,111222333,1319.05,USD,124.94,A1222333,\"\"\n"\
                                                      "2021-03-30,PO-9999,\"\",1319.05,GBP,176.66,A1222333,\"#{invoice_errors}\"\n")
      end
    end
  end
end
