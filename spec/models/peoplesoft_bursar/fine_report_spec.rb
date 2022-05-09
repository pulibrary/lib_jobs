# frozen_string_literal: true
require 'rails_helper'

RSpec.describe PeoplesoftBursar::FineReport, type: :model do
  let(:sftp_entry1) { instance_double("Net::SFTP::Protocol::V01::Name", name: "abc.csv") }
  let(:sftp_entry2) { instance_double("Net::SFTP::Protocol::V01::Name", name: "abc.xml") }
  let(:sftp_session) { instance_double("Net::SFTP::Session", dir: sftp_dir) }
  let(:sftp_dir) { instance_double("Net::SFTP::Operations::Dir") }
  let(:fine_report) { described_class.new }

  before do
    allow(sftp_dir).to receive(:foreach).and_yield(sftp_entry1).and_yield(sftp_entry2)
    # only 1 & 3 should get downloaded
    allow(sftp_session).to receive(:download!).with("/alma/bursar/abc.csv").and_return(Rails.root.join('spec', 'fixtures', 'bursar_fine.csv').read)
    allow(sftp_session).to receive(:rename).with("/alma/bursar/abc.csv", "/alma/bursar/abc.csv.processed")
    allow(Net::SFTP).to receive(:start).and_yield(sftp_session)
  end

  describe "#to_s" do
    it "generates an output string" do
      expect(fine_report.to_s).to eq("0000000019 0000000000549.25 41001 \n" \
        "999991234 240000012000      000000000003.00 N 11122233300006421              021722 Damaged item fine\n" \
        "999993330 240000012000      000000000003.00 N 11122233310006421              022222 Damaged item fine\n" \
        "999991234 240000012000      000000000001.00 N 11122233320006421              022222 Damaged item fine\n" \
        "999991234 240000012000      000000000001.50 N 11122233330006421              022222 Damaged item fine\n" \
        "999991234 240000012000      000000000003.25 N 11122233340006421              022222 Damaged item fine\n" \
        "999991234 240000012000      000000000002.00 N 11122233350006421              022222 Damaged item fine\n" \
        "999991234 240000012000      000000000002.50 N 11122233360006421              022222 Damaged item fine\n" \
        "999993330 240000012000      000000000003.00 N 11122233370006421              022322 Damaged item fine\n" \
        "999993330 240000012000      000000000002.00 N 11122233380006421              022322 Damaged item fine\n" \
        "999993330 240000012000      000000000002.00 N 11122233390006421              022322 Damaged item fine\n" \
        "999993330 240000012000      000000000006.00 N 11122233400006421              022322 Damaged item fine\n" \
        "999993330 240000012000      000000000020.00 N 11122233410006421              022322 Damaged item fine\n" \
        "999993330 240000012000      000000000050.00 N 11122233420006421              022222 Lost item process fee\n" \
        "940000258 240000012000      000000000050.00 N 11122233430006421              021622 Lost item process fee\n" \
        "999993330 240000012000      000000000050.00 N 11122233440006421              050522 Lost item process fee\n" \
        "940000258 240000012000      000000000050.00 N 11122233450006421              021622 Lost item replacement fee\n" \
        "999991234 240000012000      000000000100.00 N 11122233460006421              021722 Lost item replacement fee\n" \
        "999991234 240000012000      000000000100.00 N 11122233470006421              022122 Lost item replacement fee\n" \
        "999991234 240000012000      000000000100.00 N 11122233480006421              022222 Lost item replacement fee\n") \
    end
  end

  describe "#generate_bursar_file" do
    it "generates an output file with the report in it" do
      fine_report.generate_bursar_file('/tmp/file')
      data = File.read('/tmp/file')
      expect(data).to eq(fine_report.to_s)
    end
  end
end
