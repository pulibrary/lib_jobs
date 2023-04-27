# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(AlmaSubmitcollection::HostRecord) do
  let(:mms_ids) { ["9933584373506421", "997007993506421"] }
  let(:host_file) { Pathname.new(file_fixture_path).join("alma", 'host_record.xml').to_s }
  let(:record) { MARC::XMLReader.new(host_file).first }
  before do
    stub_alma_bibs(ids: mms_ids, status: 200, fixture: "alma_bibs.xml", apikey: '1234')
  end
  describe('#constituent_records') do
    it('returns an array of MARC records') do
      expect(described_class.new(record).constituent_records.length).to eq(8)
    end
  end
end
