# frozen_string_literal: true
module AirtableStubbing
  BASE_AIRTABLE_URL = "https://api.airtable.com/v0/appv7XA5FWS7DG9oe/tblM0iymGN5oqDUVm?fields%5B%5D=fld0MfgMlZd364YTR&fields%5B%5D=fld4JloN0LxiFaTiw&fields%5B%5D=fld9NYFQePrPxbJJW&fields%5B%5D=fldCCTbVNKKBFXxrp&fields%5B%5D=fldGzh0SHZqlFk3aU&fields%5B%5D=fldKZxmtofNbXW4qS&fields%5B%5D=fldnKprqGraSvNTJK&fields%5B%5D=fldL7tm4jVvYksIwl&fields%5B%5D=fldULoOUDSpoEpdAP&fields%5B%5D=fldXw9janMHvhBWvO&fields%5B%5D=fldbnDHHhDNlc2Lx8&fields%5B%5D=fldbquJ6Hn2eq1V2h&fields%5B%5D=fldvENk2uiLDHmYSw&fields%5B%5D=fldgarsg3FzD8xpE4&fields%5B%5D=fldqulY6ehd5aIbR1&fields%5B%5D=fldusiuPpfSql6vSk&fields%5B%5D=fldw0mjDdB48HstnB&fields%5B%5D=fldxpCzkJmhEkVqZt&fields%5B%5D=fldypTXdkQGpYgVDC&fields%5B%5D=fldz6yBenvTjdClXZ&returnFieldsByFieldId=true"
  def stub_airtable(offset: false, empty: false)
    if offset
      stub_airtable_with_offset
    elsif empty
      stub_airtable_without_offset_empty_records
    else
      stub_airtable_without_offset
    end
  end

  def stub_airtable_with_offset
    with_offset_airtable_path = Pathname.new(file_fixture_path).join("air_table", 'records_with_offset.json')
    stub_request(:get, BASE_AIRTABLE_URL)
      .with(headers: {
              'Authorization' => 'Bearer FAKE_AIRTABLE_TOKEN'
            })
      .to_return(status: 200, body: File.read(with_offset_airtable_path))

    without_offset_airtable_path = Pathname.new(file_fixture_path).join("air_table", 'records_no_offset.json')
    stub_request(:get, "#{BASE_AIRTABLE_URL}&offset=naeQu2ul/Ash6eiQu")
      .with(headers: {
              'Authorization' => 'Bearer FAKE_AIRTABLE_TOKEN'
            })
      .to_return(status: 200, body: File.read(without_offset_airtable_path))
  end

  def stub_airtable_without_offset
    airtable_path = Pathname.new(file_fixture_path).join("air_table", 'records_no_offset.json')
    stub_request(:get, BASE_AIRTABLE_URL)
      .with(headers: {
              'Authorization' => 'Bearer FAKE_AIRTABLE_TOKEN'
            })
      .to_return(status: 200, body: File.read(airtable_path))
  end

  def stub_airtable_without_offset_empty_records
    airtable_path = Pathname.new(file_fixture_path).join("air_table", 'records_no_offset_empty_records.json')
    stub_request(:get, BASE_AIRTABLE_URL)
      .with(headers: {
              'Authorization' => 'Bearer FAKE_AIRTABLE_TOKEN'
            })
      .to_return(status: 200, body: File.read(airtable_path))
  end
end

RSpec.configure do |config|
  config.include AirtableStubbing
end
