# frozen_string_literal: true
require 'rails_helper'

RSpec.describe PeoplesoftVoucher::VoucherFeed, type: :model do
  include_context 'sftp'

  let(:today) { Time.zone.now.strftime("%m%d%Y") }
  let(:onbase_today) { Time.zone.now .strftime("%Y%m%d") }
  let(:sftp_entry1) { instance_double("Net::SFTP::Protocol::V01::Name", name: "abc.xml") }

  describe "#run" do
    it "generates an xml file" do
      travel_to Time.zone.local(2024)
      allow(sftp_dir).to receive(:foreach).and_yield(sftp_entry1)
      # only 1 & 3 should get downloaded
      allow(sftp_session).to receive(:download!).with("/alma/invoices/abc.xml").and_return(Rails.root.join('spec', 'fixtures', 'invoice_export_202118300518.xml').read)
      allow(sftp_session).to receive(:rename).with("/alma/invoices/abc.xml", "/alma/invoices/abc.xml.processed")

      voucher_feed = described_class.new(onbase_output_base_dir: '/tmp', peoplesoft_output_base_dir: '/tmp')
      expect { expect(voucher_feed.run).to be_truthy }.to change { ActionMailer::Base.deliveries.count }.by(1)
      expect(sftp_session).to have_received(:download!).with("/alma/invoices/abc.xml")
      expect(sftp_session).to have_received(:rename).with("/alma/invoices/abc.xml", "/alma/invoices/abc.xml.processed")
      data_set = DataSet.last
      expect(data_set.category).to eq("VoucherFeed")
      expect(data_set.data).to eq("Lib Vendor Invoice Date,Invoice No,Vendor Code,Vendor Id,Invoice Amount,Invoice Curency,Local Amount,Voucher ID,Errors\n"\
                                  "2021-03-30,PO-9999,XXX,111222333,1319.05,USD,124.94,A020RVUO,\"\"\n")
      expect(data_set.report_time).to eq(Time.zone.now.midnight)
      data = File.read("/tmp/alma_voucher_#{today}.XML")
      expect(data).to eq(File.open(Rails.root.join('spec', 'fixtures', 'finance_invoice.xml')).read)
      data = File.read("/tmp/Library Invoice Keyword Update_#{onbase_today}.csv")
      expect(data).to eq("\"2021-03-30\",\"PO-9999\",\"XXX\",\"1319.05\",\"A020RVUO\"\n")
      File.delete("/tmp/alma_voucher_#{today}.XML")
      File.delete("/tmp/Library Invoice Keyword Update_#{onbase_today}.csv")
      confirm_email = ActionMailer::Base.deliveries.last
      expect(confirm_email.subject).to eq("Alma to Peoplesoft Voucher Feed Results")
      expect(confirm_email.html_part.body.to_s).to include("No errors were found with the invoices")
      expect(confirm_email.html_part.body.to_s).not_to include("No invoices available to process")
      travel_back
    end

    it "does not generates xml files if no invoices are present" do
      allow(sftp_dir).to receive(:foreach)

      voucher_feed = described_class.new(onbase_output_base_dir: '/tmp', peoplesoft_output_base_dir: '/tmp')
      expect { expect(voucher_feed.run).to be_truthy }.to change { ActionMailer::Base.deliveries.count }.by(1)
      data_set = DataSet.last
      expect(data_set.category).to eq("VoucherFeed")
      expect(data_set.data).to eq("")
      expect(data_set.report_time).to eq(Time.zone.now.midnight)
      expect(File.exist?("/tmp/alma_voucher_#{today}.XML")).to be_falsey
      expect(File.exist?("/tmp/Library Invoice Keyword Update_#{onbase_today}.csv")).to be_falsey
      confirm_email = ActionMailer::Base.deliveries.last
      expect(confirm_email.subject).to eq("Alma to Peoplesoft Voucher Feed Results")
      expect(confirm_email.html_part.body.to_s).to include("No errors were found with the invoices")
      expect(confirm_email.html_part.body.to_s).to include("No invoices available to process")
    end

    it "does not generates xml files if no valid invoices are present" do
      allow(sftp_dir).to receive(:foreach).and_yield(sftp_entry1)
      # only 1 & 3 should get downloaded
      allow(sftp_session).to receive(:download!).with("/alma/invoices/abc.xml").and_return(Rails.root.join('spec', 'fixtures', 'invalid_invoice.xml').read)
      allow(sftp_session).to receive(:rename).with("/alma/invoices/abc.xml", "/alma/invoices/abc.xml.processed")

      voucher_feed = described_class.new(onbase_output_base_dir: '/tmp', peoplesoft_output_base_dir: '/tmp')
      expect { expect(voucher_feed.run).to be_truthy }.to change { ActionMailer::Base.deliveries.count }.by(1)
      expect(sftp_session).to have_received(:download!).with("/alma/invoices/abc.xml")
      expect(sftp_session).to have_received(:rename).with("/alma/invoices/abc.xml", "/alma/invoices/abc.xml.processed")
      data_set = DataSet.last
      invoice_errors = "Invalid vendor_id: vendor_id can not be blank, Line Item Invalid: primary fund can not be blank, Line Item Invalid: primary department can not be blank, "\
                       "Invalid reporting code: must be numeric and can not be blank, Invalid invoice date: must be between four years old and one month into the future"
      expect(data_set.category).to eq("VoucherFeed")
      expect(data_set.data).to eq("Lib Vendor Invoice Date,Invoice No,Vendor Code,Vendor Id,Invoice Amount,Invoice Curency,Local Amount,Voucher ID,Errors\n"\
                                  "1996-03-30,PO-9999,XXX,\"\",1319.05,GBP,176.66,A020RVUO,\"#{invoice_errors}\"\n")
      expect(data_set.report_time).to eq(Time.zone.now.midnight)
      expect(File.exist?("/tmp/alma_voucher_#{today}.XML")).to be_falsey
      expect(File.exist?("/tmp/Library Invoice Keyword Update_#{onbase_today}.csv")).to be_falsey
      confirm_email = ActionMailer::Base.deliveries.last
      expect(confirm_email.subject).to eq("Alma to Peoplesoft Voucher Feed Results")
      expect(confirm_email.html_part.body.to_s).to include("1996-03-30</td><td>PO-9999</td><td>XXX</td><td></td><td>1319.05</td><td>GBP</td><td>176.66</td><td>A020RVUO</td>"\
                                                           "<td>#{invoice_errors}</td>")
      expect(confirm_email.html_part.body.to_s).to include("No invoices available to process")
    end

    context 'job is turned off' do
      before do
        allow(Flipflop).to receive(:peoplesoft_voucher?).and_return(false)
      end
      it 'logs that it is turned off' do
        voucher_feed = described_class.new(onbase_output_base_dir: '/tmp', peoplesoft_output_base_dir: '/tmp', alma_xml_invoice_list: nil)
        voucher_feed.run
        data_set = DataSet.last
        expect(data_set.data).to eq('Voucher feed job is typically scheduled for this time, but it is turned off.  Go to /features to turn it back on.')
      end
      it 'does not email anybody' do
        voucher_feed = described_class.new(onbase_output_base_dir: '/tmp', peoplesoft_output_base_dir: '/tmp', alma_xml_invoice_list: nil)
        expect { voucher_feed.run }.not_to change { ActionMailer::Base.deliveries.count }
      end
    end
  end
end
