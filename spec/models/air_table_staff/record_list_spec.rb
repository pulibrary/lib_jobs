# frozen_string_literal: true
require 'rails_helper'

BASE_AIRTABLE_URL = 'https://api.airtable.com/v0/appv7XA5FWS7DG9oe/Synchronized%20Staff%20Directory%20View?view=Grid%20view'

RSpec.describe AirTableStaff::RecordList do
  context 'when the airtable response is not paginated' do
    before do
      stub_request(:get, BASE_AIRTABLE_URL)
        .with(
         headers: {
           'Authorization' => 'Bearer FAKE_AIRTABLE_TOKEN'
         }
       )
        .to_return(status: 200, body: File.read(file_fixture('air_table/records_no_offset.json')), headers: {})
    end
    it 'creates an array with data from a single call to the HTTP API' do
      list = described_class.new.to_a

      expect(list.length).to eq(1)

      first_person = list[0].to_a
      expect(first_person[0]).to eq('123') # puid
      expect(first_person[3]).to eq('Phillip Librarian') # name

      expect(WebMock).to have_requested(:get, BASE_AIRTABLE_URL).once
    end
  end
  context 'when the airtable response is paginated' do
    before do
      stub_request(:get, BASE_AIRTABLE_URL)
        .with(
         headers: {
           'Authorization' => 'Bearer FAKE_AIRTABLE_TOKEN'
         }
       )
        .to_return(status: 200, body: File.read(file_fixture('air_table/records_with_offset.json')), headers: {})
      stub_request(:get, "#{BASE_AIRTABLE_URL}&offset=naeQu2ul/Ash6eiQu")
        .with(
         headers: {
           'Authorization' => 'Bearer FAKE_AIRTABLE_TOKEN'
         }
       )
        .to_return(status: 200, body: File.read(file_fixture('air_table/records_no_offset.json')), headers: {})
    end
    it 'creates an array with data from multiple calls to the HTTP API' do
      list = described_class.new.to_a

      expect(list.length).to eq(2)

      first_person = list[0].to_a
      expect(first_person[0]).to eq('456') # puid
      expect(first_person[3]).to eq('Drema Carmant') # name

      second_person = list[1].to_a
      expect(second_person[0]).to eq('123') # puid
      expect(second_person[3]).to eq('Phillip Librarian') # name

      expect(WebMock).to have_requested(:get, BASE_AIRTABLE_URL).once
      expect(WebMock).to have_requested(:get, "#{BASE_AIRTABLE_URL}&offset=naeQu2ul/Ash6eiQu").once
    end
    context 'when we run it multiple times' do
      it 'gives us the same data without additional network calls' do
        list = described_class.new
        first_time = list.to_a
        second_time = list.to_a

        expect(first_time).to eq(second_time)
        expect(WebMock).to have_requested(:get, BASE_AIRTABLE_URL).once
        expect(WebMock).to have_requested(:get, "#{BASE_AIRTABLE_URL}&offset=naeQu2ul/Ash6eiQu").once
      end
    end
  end
end
