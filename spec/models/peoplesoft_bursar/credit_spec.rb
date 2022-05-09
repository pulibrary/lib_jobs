# frozen_string_literal: true
require 'rails_helper'

RSpec.describe PeoplesoftBursar::Credit, type: :model do
  let(:amount) { described_class.new(patron_id: "123", amount: 5.00, date: Date.parse('20200630')) }
  describe "#to_s" do
    it "generates formatted output " do
      expect(amount.to_s).to eq("123 240000012000 1204 000000000005.00 Y                                063020 Library Credit")
    end

    context "a different term" do
      let(:amount) { described_class.new(patron_id: "123", amount: 5.00, date: Date.parse('20220630')) }

      it "generates formatted output " do
        expect(amount.to_s).to eq("123 240000012000 1224 000000000005.00 Y                                063022 Library Credit")
      end
    end

    context "after June 30th" do
      let(:amount) { described_class.new(patron_id: "123", amount: 5.00, date: Date.parse('20220701')) }

      it "generates formatted output " do
        expect(amount.to_s).to eq("123 240000012000 1232 000000000005.00 Y                                070122 Library Credit")
      end
    end

    context "negative amount" do
      let(:amount) { described_class.new(patron_id: "123", amount: -5.67, date: Date.parse('20220701')) }

      it "puts in the absolute value " do
        expect(amount.to_s).to eq("123 240000012000 1232 000000000005.67 Y                                070122 Library Credit")
      end
    end
  end
end
