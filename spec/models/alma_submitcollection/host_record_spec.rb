# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(AlmaSubmitcollection::HostRecord) do
  let(:mms_ids) { ["9933584373506421", "997007993506421"] }
  before do
    stub_alma_ids(ids: mms_ids, status: 200, fixture: "alma_bibs.xml")
  end
  describe('#get_constituent_records') do
    it('returns an array of MARC records') do
      expect(described_class.new.length).to eq(5)
    end
  end
end
