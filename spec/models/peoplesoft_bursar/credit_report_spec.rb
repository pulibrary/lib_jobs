# frozen_string_literal: true
require 'rails_helper'

RSpec.describe PeoplesoftBursar::CreditReport, type: :model do
  include_context 'sftp'

  let(:sftp_entry1) { instance_double("Net::SFTP::Protocol::V01::Name", name: "abc.xml") }
  let(:sftp_entry2) { instance_double("Net::SFTP::Protocol::V01::Name", name: "abc.csv") }
  let(:credit_report) { described_class.new }

  before do
    allow(sftp_dir).to receive(:foreach).and_yield(sftp_entry1).and_yield(sftp_entry2)
    # only 1 & 3 should get downloaded
    allow(sftp_session).to receive(:download!).with("/alma/bursar/abc.xml").and_return(Rails.root.join('spec', 'fixtures', 'bursar_credit.xml').read)
    allow(sftp_session).to receive(:rename).with("/alma/bursar/abc.xml", "/alma/bursar/abc.xml.processed")
  end

  describe "#to_s" do
    it "generates an output string" do
      expect(credit_report.to_s).to eq("0000000004 -000000000108.25 41001 \n" \
                                       "111111111 240000012000 1224 000000000003.00 Y                                022322 Library Credit\n" \
                                       "211111111 240000012000 1224 000000000100.00 Y                                022322 Library Credit\n" \
                                       "211111111 240000012000 1224 000000000003.25 Y                                022322 Library Credit\n" \
                                       "211111111 240000012000 1224 000000000002.00 Y                                022322 Library Credit\n")
    end
  end

  describe "#generate_bursar_file" do
    it "generates an output file with the report in it" do
      credit_report.generate_bursar_file('/tmp/file')
      data = File.read('/tmp/file')
      expect(data).to eq(credit_report.to_s)
    end
  end
end
