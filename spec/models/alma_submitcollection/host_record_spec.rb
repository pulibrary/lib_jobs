# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(AlmaSubmitcollection::HostRecord) do
  describe('#get_constituent_records') do
    it('returns an array of MARC records') do
      expect(described_class.new.length).to eq(5)
    end
  end
end
