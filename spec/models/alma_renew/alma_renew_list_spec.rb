# frozen_string_literal: true
require 'rails_helper'

RSpec.describe AlmaRenew::AlmaRenewList, type: :model do
  subject(:alma_renew_list) { described_class.new }

  let(:sftp_entry1) { instance_double("Net::SFTP::Protocol::V01::Name", name: "abc.csv") }
  let(:sftp_entry2) { instance_double("Net::SFTP::Protocol::V01::Name", name: "abc.csv.processed") }
  let(:sftp_entry3) { instance_double("Net::SFTP::Protocol::V01::Name", name: "123.csv") }
  let(:sftp_session) { instance_double("Net::SFTP::Session", dir: sftp_dir) }
  let(:sftp_dir) { instance_double("Net::SFTP::Operations::Dir") }

  let(:invoice_errors) do
    "Invalid vendor_id: vendor_id can not be blank,"\
    " Line Item Invalid: primary fund can not be blank,"\
    " Line Item Invalid: primary department can not be blank,"\
    " Invalid reporting code: must be numeric and can not be blank,"\
    " Invalid invoice date: must be between four years old and one month into the future"
  end

  before do
    allow(sftp_dir).to receive(:foreach).and_yield(sftp_entry1).and_yield(sftp_entry2)
    # only 1 should get downloaded
    pin_time_to_valid_invoice_list
    allow(sftp_session).to receive(:download!).with("/alma/scsb_renewals/abc.csv").and_return(Rails.root.join('spec', 'fixtures', 'renew.csv').read)
    allow(sftp_session).to receive(:rename).with("/alma/scsb_renewals/abc.csv", "/alma/scsb_renewals/abc.csv.processed")
    allow(Net::SFTP).to receive(:start).and_yield(sftp_session)
  end

  describe "#renew_items" do
    it "parses the list " do
      expect(alma_renew_list.renew_items).to contain_exactly(
        { "Barcode" => "32044061963013", "Patron Group" => "UGRD Undergraduate", "Primary Identifier" => "999999999", "Expiry Date" => "2023-10-31" },
        { "Barcode" => "33433084897390", "Patron Group" => "SENR Senior Undergraduate", "Primary Identifier" => "999999999", "Expiry Date" => "2022-05-31" },
        { "Barcode" => "CU53967402", "Patron Group" => "Graduate Student", "Primary Identifier" => "999999999", "Expiry Date" => "2022-10-31" },
        { "Barcode" => "CU63769409", "Patron Group" => "P Faculty & Professional", "Primary Identifier" => "999999999", "Expiry Date" => "2023-10-31" },
        { "Barcode" => "CU63769408", "Patron Group" => "REG Regular Staff", "Primary Identifier" => "999999999", "Expiry Date" => "2022-12-31" }
      )
      expect(sftp_session).to have_received(:download!).with("/alma/scsb_renewals/abc.csv")
    end

    context "an empty list" do
      before do
        allow(sftp_session).to receive(:download!).with("/alma/scsb_renewals/abc.csv").and_return(Rails.root.join('spec', 'fixtures', 'empty_renew.csv').read)
      end

      it "parses the list " do
        expect(alma_renew_list.renew_items).to be_empty
      end
    end
  end

  describe "#mark_files_as_processed" do
    it "moves the files" do
      alma_renew_list.mark_files_as_processed
      expect(sftp_session).to have_received(:rename).with("/alma/scsb_renewals/abc.csv", "/alma/scsb_renewals/abc.csv.processed")
    end
  end
end
