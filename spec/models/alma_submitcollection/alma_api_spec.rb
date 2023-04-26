# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(AlmaSubmitcollection::AlmaApi) do
  let(:mms_ids) { ["9933584373506421", "997007993506421"] }
  before do
    stub_alma_bibs(ids: mms_ids, status: 200, fixture: "alma_bibs.xml", apikey: '1234')
  end

  describe('#bib_record_call') do
    it('parses correctly') do
      response = described_class.new.bib_record_call(mms_ids)
      expect { Nokogiri::XML(response.body) }.not_to raise_error
    end
  end
end
