# frozen_string_literal: true
require 'rails_helper'

RSpec.describe VoucherFeed, type: :model do
  let(:today) { Time.zone.now.strftime("%m%d%Y") }
  let(:onbase_today) { Time.zone.now .strftime("%Y%m%d") }
  let(:sftp_entry1) { instance_double("Net::SFTP::Protocol::V01::Name", name: "abc.xml") }
  let(:sftp_session) { instance_double("Net::SFTP::Session", dir: sftp_dir) }
  let(:sftp_dir) { instance_double("Net::SFTP::Operations::Dir") }

  describe "#run" do
    it "generates an xml file" do
      allow(sftp_dir).to receive(:foreach).and_yield(sftp_entry1)
      # only 1 & 3 should get downloaded
      allow(sftp_session).to receive(:download!).with("/alma/invoices/abc.xml").and_return(Rails.root.join('spec', 'fixtures', 'invoice_export_202118300518.xml').read)
      allow(sftp_session).to receive(:rename).with("/alma/invoices/abc.xml", "/alma/invoices/abc.xml.processed")
      allow(Net::SFTP).to receive(:start).and_yield(sftp_session)

      voucher_feed = described_class.new(onbase_output_base_dir: '/tmp', peoplesoft_output_base_dir: '/tmp')
      expect { expect(voucher_feed.run).to be_truthy }.to change { ActionMailer::Base.deliveries.count }.by(1)
      expect(sftp_session).to have_received(:download!).with("/alma/invoices/abc.xml")
      expect(sftp_session).to have_received(:rename).with("/alma/invoices/abc.xml", "/alma/invoices/abc.xml.processed")
      data_set = DataSet.last
      expect(data_set.category).to eq("VoucherFeed")
      expect(data_set.data).to eq("Lib Vendor Invoice Date,Invoice No,Vendor Code,Invoice Amount,Invoice Curency,Local Amount,Voucher ID,Errors\n"\
                                  "2021-03-30,PO-9999,111222333,1319.05,USD,124.94,A1222333,\"\"\n")
      expect(data_set.report_time).to eq(Time.zone.now.midnight)
      data = File.read("/tmp/alma_voucher_#{today}.XML")
      expect(data).to eq(File.open(Rails.root.join('spec', 'fixtures', 'finance_invoice.xml')).read)
      data = File.read("/tmp/Library Invoice Keyword Update_#{onbase_today}.csv")
      expect(data).to eq("\"2021-03-30\",\"PO-9999\",\"111222333\",\"1319.05\",\"A1222333\"\n")
    end
  end
end
