# frozen_string_literal: true
require 'rails_helper'

RSpec.describe AlmaFundAdjustment::FundAdjustment, type: :model do
  subject(:adjustment) do
    described_class.new({ "FUND_EXTERNAL_ID" => "12345|Z9999",
                          "FISCAL_PERIOD_ID" => "22",
                          "AMOUNT" => "13.36",
                          "TRANSACTION_REFERENCE_NUMBER" => "123456",
                          "TRANSACTION_NOTE" => "Online Entry | A Fund We have | 07/14/2021" })
  end

  describe "#unique_id" do
    it "cobines the external id and the note" do
      expect(adjustment.unique_id).to eq("123456-Online Entry | A Fund We have | 07/14/2021")
    end
  end

  describe "#original_amount" do
    it "gives the original amount" do
      expect(adjustment.original_amount).to eq("13.36")
    end
  end

  describe "#transposed_amount" do
    it "returns the negative of the original" do
      expect(adjustment.transposed_amount).to eq("-13.36")
    end

    context "A negative amount" do
      subject(:adjustment) do
        described_class.new({ "FUND_EXTERNAL_ID" => "12345|Z9999",
                              "FISCAL_PERIOD_ID" => "22",
                              "AMOUNT" => "-13.36",
                              "TRANSACTION_REFERENCE_NUMBER" => "123456",
                              "TRANSACTION_NOTE" => "Online Entry | A Fund We have | 07/14/2021" })
      end

      it "returns the negative of the original" do
        expect(adjustment.transposed_amount).to eq("13.36")
      end
    end

    context "A zero amount" do
      subject(:adjustment) do
        described_class.new({ "FUND_EXTERNAL_ID" => "12345|Z9999",
                              "FISCAL_PERIOD_ID" => "22",
                              "AMOUNT" => "0.00",
                              "TRANSACTION_REFERENCE_NUMBER" => "123456",
                              "TRANSACTION_NOTE" => "Online Entry | A Fund We have | 07/14/2021" })
      end

      it "returns the original" do
        expect(adjustment.transposed_amount).to eq("0.00")
      end
    end
  end

  describe "#adjusted_row" do
    it "contains the transpoxed amount" do
      expect(adjustment.adjusted_row["AMOUNT"]).to eq("-13.36")
    end
  end
end
