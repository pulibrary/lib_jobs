# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(AlmaSubmitcollection::HostRecord) do
  # use the new host fixture that Mark exported
  # update constituent_ids with the two ids from the new record
  # Change the test so that is testing the [] 001 fields is the array in line 8
  let(:constituent_ids) { ["9923749023506421", "997573203506421", "997573243506421", "997573403506421", "99753293506421", "997573283506421", "997573343506421", "997573163506421"] }
  let(:host_file) { Pathname.new(file_fixture_path).join("alma", 'host_record.xml').to_s }
  let(:record) { MARC::XMLReader.new(host_file).first }
  before do
    stub_alma_bibs(ids: constituent_ids, status: 200, fixture: "constituent_records.xml", apikey: '1234')
  end
  describe('#constituent_records') do
    it('returns an array of MARC records') do
      expect(described_class.new(record).constituent_records)
    end
  end
end
