# frozen_string_literal: true
require 'rails_helper'

RSpec.describe AlmaRenew::AlmaRenewList, type: :model, file_download: true do
  include_context 'sftp'
  subject(:alma_renew_list) { described_class.new }

  let(:sftp_entry1) { instance_double("Net::SFTP::Protocol::V01::Name", name: "abc.csv") }
  let(:sftp_entry2) { instance_double("Net::SFTP::Protocol::V01::Name", name: "abc.csv.processed") }
  let(:sftp_entry3) { instance_double("Net::SFTP::Protocol::V01::Name", name: "123.csv") }

  let(:invoice_errors) do
    "Invalid vendor_id: vendor_id can not be blank,"\
    " Line Item Invalid: primary fund can not be blank,"\
    " Line Item Invalid: primary department can not be blank,"\
    " Invalid reporting code: must be numeric and can not be blank,"\
    " Invalid invoice date: must be between four years old and one month into the future"
  end
  let(:temp_file_one) { Tempfile.new(encoding: 'ascii-8bit') }

  before do
    allow(Tempfile).to receive(:new).and_return(temp_file_one)
    allow(sftp_dir).to receive(:foreach).and_yield(sftp_entry1).and_yield(sftp_entry2)
    # only 1 should get downloaded
    pin_time_to_valid_invoice_list
    allow(sftp_session).to receive(:download!).with("/alma/scsb_renewals/abc.csv").and_return(Rails.root.join('spec', 'fixtures', 'renew.csv').read)
    allow(sftp_session).to receive(:rename).with("/alma/scsb_renewals/abc.csv", "/alma/scsb_renewals/abc.csv.processed")
  end

  around do |example|
    temp_file_one.write(File.open(File.join('spec', 'fixtures', 'renew.csv')).read)
    example.run
  end

  describe "#renew_item_list" do
    let(:expected_item_list) do
      [
        { "Barcode" => "32044061963013", "Patron Group" => "UGRD Undergraduate", "Primary Identifier" => "999999999", "Expiry Date" => "2023-10-31" },
        { "Barcode" => "33433084897390", "Patron Group" => "SENR Senior Undergraduate", "Primary Identifier" => "999999999", "Expiry Date" => "2022-05-31" },
        { "Barcode" => "CU53967402", "Patron Group" => "Graduate Student", "Primary Identifier" => "999999999", "Expiry Date" => "2022-10-31" },
        { "Barcode" => "CU63769409", "Patron Group" => "P Faculty & Professional", "Primary Identifier" => "999999999", "Expiry Date" => "2023-10-31" },
        { "Barcode" => "CU63769408", "Patron Group" => "REG Regular Staff", "Primary Identifier" => "999999999", "Expiry Date" => "2022-12-31" }
      ]
    end
    it "creates a list of items" do
      expect(alma_renew_list.renew_item_list).to be_instance_of(Array)
      expect(alma_renew_list.renew_item_list.first).to be_instance_of(AlmaRenew::Item)
      expect(alma_renew_list.renew_item_list.count).to eq 5
      expect(alma_renew_list.renew_item_list.map(&:to_h)).to match_array(expected_item_list)
      expect(sftp_session).to have_received(:download!).with("/alma/scsb_renewals/abc.csv")
    end

    context "an empty list" do
      before do
        allow(sftp_session).to receive(:download!).with("/alma/scsb_renewals/abc.csv").and_return(Rails.root.join('spec', 'fixtures', 'empty_renew.csv').read)
      end

      it "parses the list " do
        expect(alma_renew_list.renew_item_list).to be_empty
      end
    end

    context "a list with an incorrect header name" do
      before do
        allow(sftp_session).to receive(:download!).with("/alma/scsb_renewals/abc.csv").and_return(Rails.root.join('spec', 'fixtures', 'renew_invalid_headers.csv').read)
      end
      it "throws an error" do
        expect { described_class.new }.to raise_error(CSVValidator::InvalidHeadersError)
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
