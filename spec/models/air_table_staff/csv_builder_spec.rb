# frozen_string_literal: true
require 'rails_helper'

RSpec.describe AirTableStaff::CSVBuilder do
  before do
    stub_request(:get, "https://api.airtable.com/v0/appv7XA5FWS7DG9oe/Synchronized%20Staff%20Directory%20View?view=Grid%20view")
      .with(
       headers: {
         'Authorization' => 'Bearer FAKE_AIRTABLE_TOKEN'
       }
     )
      .to_return(status: 200, body: File.read(file_fixture('air_table/records_no_offset.json')), headers: {})
  end
  it 'creates a CSV string with data from the HTTP API' do
    # The following CSV contains new lines within a single cell.
    # Since the cell is in in double quotes, it will still be read
    # as a single cell within a single row"
    expected = <<~END_CSV
            puid,netid,phone,name,lastName,firstName,email,address,building,department,division,unit,team,title,areasOfStudy,websiteUrl,bios,expertise
            123,ab123,(123) 123-1234,Phillip Librarian,Librarian,Phillip,ab123@princeton.edu,123 Stokes,Stokes,Stokes,,,,Library Collections Specialist V,Virtual Reality,,"Hello
            My research interests
            are

            fantastic!",
        END_CSV
    directory = described_class.new
    expect(directory.to_csv).to eq(expected)
  end
end
