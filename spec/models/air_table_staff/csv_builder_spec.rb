# frozen_string_literal: true
require 'rails_helper'

RSpec.describe AirTableStaff::CSVBuilder do
  before do
    stub_airtable
  end
  it 'creates a CSV string with data from the HTTP API' do
    # The following CSV contains new lines within a single cell.
    # Since the cell is in in double quotes, it will still be read
    # as a single cell within a single row"
    expected = <<~END_CSV
            puid,netid,phone,name,lastName,firstName,email,address,building,department,division,unit,team,title,areasOfStudy,websiteUrl,bios,expertise,mySchedulerLink,otherEntities,pronouns
            123,ab123,(123) 123-1234,Phillip Librarian,Librarian,Phillip,ab123@princeton.edu,123 Stokes,Stokes,Special Collections,Special and Distinctive Collections,,,Library Collections Specialist V,Virtual Reality,,"Hello
            My research interests
            are

            fantastic!",,https://example.com,Industrial Relations//James Madison Program,he/him/his
        END_CSV
    directory = described_class.new
    expect(directory.to_csv).to eq(expected)
  end
end
