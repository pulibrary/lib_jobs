# frozen_string_literal: true
require 'rails_helper'

RSpec.describe PeoplesoftBursar::Fine, type: :model do
  let(:amount) { described_class.new(patron_id: "123", amount: 7.50, date: Date.parse('20200630'), fine_id: '123', fine_type: 'Library Fines') }
  describe "#to_s" do
    it "generates formatted output " do
      expect(amount.to_s).to eq("123 240000012000      000000000007.50 N 123                            063020 Library Fines")
    end
  end
end
