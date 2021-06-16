# frozen_string_literal: true
require 'rails_helper'

RSpec.describe PeoplesoftVoucher::FinanceXmlInvoice, type: :model do
  describe "#run" do
    let(:sftp_entry) { instance_double("Net::SFTP::Protocol::V01::Name", name: "abc.xml") }
    let(:sftp_session) { instance_double("Net::SFTP::Session", dir: sftp_dir) }
    let(:sftp_dir) { instance_double("Net::SFTP::Operations::Dir") }
    let(:alma_invoice_list) { PeoplesoftVoucher::AlmaXmlInvoiceList.new }

    let(:finance_xml) do
      File.open(Rails.root.join('spec', 'fixtures', 'finance_invoice.xml')).read
    end

    before do
      allow(sftp_dir).to receive(:foreach).and_yield(sftp_entry)
      allow(sftp_session).to receive(:download!).with("/alma/invoices/abc.xml").and_return(Rails.root.join('spec', 'fixtures', 'invoice_export_202118300518.xml').read)
      allow(Net::SFTP).to receive(:start).and_yield(sftp_session)
    end

    it "generates xml " do
      builder = Nokogiri::XML::Builder.new do |xml|
        alma_person = described_class.new(xml: xml, alma_invoice_list: alma_invoice_list)
        alma_person.convert
      end
      expect(builder.to_xml).to eq(finance_xml)
    end

    context "with real data locally" do
      let(:alma_invoice_xml) { Rails.root.join('invoice_export_202125070925.xml') }
      it "generates xml" do
        pending "Should only be run locally"
        allow(sftp_session).to receive(:download!).with("/alma/invoices/abc.xml").and_return(alma_invoice_xml.read)
        builder = Nokogiri::XML::Builder.new do |xml|
          alma_person = described_class.new(xml: xml, alma_invoice_list: alma_invoice_list)
          alma_person.convert
        end
        expect(builder.to_xml).to eq(File.open(Rails.root.join('alma_voucher_test_20210507.xml')).read)
      end
    end
  end
end
