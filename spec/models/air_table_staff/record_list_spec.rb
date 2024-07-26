# frozen_string_literal: true
require 'rails_helper'

BASE_AIRTABLE_URL = 'https://api.airtable.com/v0/appv7XA5FWS7DG9oe/tblM0iymGN5oqDUVm?fields%5B%5D=fld0MfgMlZd364YTR&fields%5B%5D=fld4JloN0LxiFaTiw&fields%5B%5D=fld9NYFQePrPxbJJW&fields%5B%5D=fldCCTbVNKKBFXxrp&fields%5B%5D=fldGzh0SHZqlFk3aU&fields%5B%5D=fldKZxmtofNbXW4qS&fields%5B%5D=fldnKprqGraSvNTJK&fields%5B%5D=fldL7tm4jVvYksIwl&fields%5B%5D=fldULoOUDSpoEpdAP&fields%5B%5D=fldXw9janMHvhBWvO&fields%5B%5D=fldbnDHHhDNlc2Lx8&fields%5B%5D=fldbquJ6Hn2eq1V2h&fields%5B%5D=fldvENk2uiLDHmYSw&fields%5B%5D=fldgarsg3FzD8xpE4&fields%5B%5D=fldqulY6ehd5aIbR1&fields%5B%5D=fldusiuPpfSql6vSk&fields%5B%5D=fldw0mjDdB48HstnB&fields%5B%5D=fldxpCzkJmhEkVqZt&fields%5B%5D=fldypTXdkQGpYgVDC&fields%5B%5D=fldz6yBenvTjdClXZ&returnFieldsByFieldId=true'

RSpec.describe AirTableStaff::RecordList do
  context 'when the airtable response is not paginated' do
    before do
      stub_airtable
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
      stub_airtable(offset: true)
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
    describe 'url length' do
      # Will need to be careful about url length - must be less than 16,000 characters
      it 'does not exceed the maximum url length' do
        expect("#{BASE_AIRTABLE_URL}&offset=naeQu2ul/Ash6eiQu".length).to be < 16_000
      end
    end
  end
end
