# frozen_string_literal: true
require 'rails_helper'

RSpec.describe PeoplesoftBursar::Report, type: :model do
  let(:list) { [FactoryBot.build(:fine)] }
  let(:report) { described_class.new(list: list) }
  describe "#to_s" do
    it "generates formatted output " do
      expect(report.to_s).to eq("0000000001 0000000000005.50 41001 \n" \
        "123 240000012000      000000000005.50 N 123                            063020 Library Fines\n")
    end

    context "has only credits" do
      let(:list) { [FactoryBot.build(:credit)] }

      it "generates formatted output " do
        expect(report.to_s).to eq("0000000001 -000000000005.50 41001 \n" \
          "123 240000012000 1204 000000000005.50 Y                                063020 Library Credit\n")
      end
    end

    context "has credits and fines" do
      let(:list) { [FactoryBot.build(:fine, amount: 10.75), FactoryBot.build(:credit)] }

      it "generates formatted output " do
        expect(report.to_s).to eq("0000000002 0000000000005.25 41001 \n" \
          "123 240000012000      000000000010.75 N 123                            063020 Library Fines\n" \
          "123 240000012000 1204 000000000005.50 Y                                063020 Library Credit\n")
      end
    end
  end
end
