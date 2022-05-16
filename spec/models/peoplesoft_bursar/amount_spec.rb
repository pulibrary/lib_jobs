# frozen_string_literal: true
require 'rails_helper'

RSpec.describe PeoplesoftBursar::Amount, type: :model do
  let(:amount) { described_class.new(patron_id: "123", term_code: 1204, amount: 5.00, reversal_indicator: 'N', fine_id: '   ', date: Date.parse('20200630'), description: "ITS A TEST") }
  describe "#to_s" do
    it "generates formatted output " do
      expect(amount.to_s).to eq("123 240000012000 1204 000000000005.00 N                                063020 ITS A TEST")
    end
  end
end
