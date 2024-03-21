# frozen_string_literal: false
require 'rails_helper'

RSpec.describe Gobi::IsbnFile, type: :model do
  include_context 'gobi_isbn'
  let(:isbn_file) { described_class.new(temp_file: temp_file_one) }

  it 'can be processed' do
    expect(isbn_file.process).to be
  end

  it 'it writes the expected data to the file' do
    isbn_file.process
    csv_file = CSV.read(new_csv_path, col_sep: "|")
    expect(csv_file.length).to eq(156)
    first_row = csv_file[0]
    expect(first_row[0]).to eq('9789775414656')
    expect(first_row[1]).to eq('RCP')
    expect(first_row[2]).to eq('123499')
  end

  describe '#published_within_five_years?' do
    # In the context of this test, the current year is 2024
    it 'treats dates with u in them as though it were a zero' do
      row = CSV::Row.new(['Begin Publication Date'], ["202u"])
      expect(isbn_file.published_within_five_years?(row:)).to be true
    end
    it 'treats 9999 as a too-old date' do
      row = CSV::Row.new(['Begin Publication Date'], ["9999"])
      expect(isbn_file.published_within_five_years?(row:)).to be false
    end
    it 'treats dates in the future as a recent date' do
      row = CSV::Row.new(['Begin Publication Date'], ["2028"])
      expect(isbn_file.published_within_five_years?(row:)).to be true
    end
    it 'returns true for recent dates' do
      row = CSV::Row.new(['Begin Publication Date'], ["2022"])
      expect(isbn_file.published_within_five_years?(row:)).to be true
    end
    it 'returns true for 2019' do
      row = CSV::Row.new(['Begin Publication Date'], ["2019"])
      expect(isbn_file.published_within_five_years?(row:)).to be true
    end
    it 'returns false for older dates' do
      row = CSV::Row.new(['Begin Publication Date'], ["2005"])
      expect(isbn_file.published_within_five_years?(row:)).to be false
    end
  end

  describe '#code_string' do
    it 'has a code string of NC when in a non-circulating location' do
      row = CSV::Row.new(['Library Code', 'Location Code'], ['arch', 'ref'])
      expect(isbn_file.code_string(row:)).to eq('NC')
    end
    it 'has a code string of RCP when in a shared location' do
      row = CSV::Row.new(['Library Code', 'Location Code'], ['recap', 'pa'])
      expect(isbn_file.code_string(row:)).to eq('RCP')
    end
    it 'has a code string of Cir for all other locations' do
      row = CSV::Row.new(['Library Code', 'Location Code'], ['anything', 'atall'])
      expect(isbn_file.code_string(row:)).to eq('Cir')
    end
  end

  describe '#relevant_library_code' do
    it 'returns false for zobsolete' do
      row = CSV::Row.new(['Library Code'], ['zobsolete'])
      expect(isbn_file.relevant_library_code?(row:)).to be false
    end
    it 'returns false for resshare' do
      row = CSV::Row.new(['Library Code'], ['resshare'])
      expect(isbn_file.relevant_library_code?(row:)).to be false
    end
    it 'returns true for other locations' do
      row = CSV::Row.new(['Library Code'], ['anything'])
      expect(isbn_file.relevant_library_code?(row:)).to be true
    end
  end

  describe '#isbns_for_report' do
    it 'returns all valid isbns' do
      row = CSV::Row.new(['ISBN Valid'], ['0195103483; 9780195103489; 0195103491; 9780195103496'])
      expect(isbn_file.isbns_for_report(row:)).to match_array(['0195103483', '9780195103489', '0195103491', '9780195103496'])
    end
    xit 'removes ten digit isbns that match a 13 digit isbn' do
      row = CSV::Row.new(['ISBN Valid'], ['0195103483; 9780195103489; 0195103491; 9780195103496'])
      expect(isbn_file.isbns_for_report(row:)).to match_array(['9780195103489', '9780195103496'])
    end
    it 'removes extra colons' do
      row = CSV::Row.new(['ISBN Valid'], ['9780195103489:'])
      expect(isbn_file.isbns_for_report(row:)).to eq(['9780195103489'])
    end
    it 'does not return invalid isbns' do
      row = CSV::Row.new(['ISBN Valid'], ['01951034830; 978019510348; 01951034; 978019510349'])
      expect(isbn_file.isbns_for_report(row:)).to be_blank
    end
  end

  describe 'repeated MMS ID with different locations and one ISBN' do
    let(:our_csv) do
      str = <<-EOT
MMS Id,Begin Publication Date,ISBN Valid,Library Code,Location Code
99113270853506421,2019,9781442214439,recap,pa
99113270853506421,2019,9781442214439,firestone,stacks
99113270853506421,2019,9781442214439,arch,ref
EOT
      CSV.new(str, headers: true)
    end
    let(:expected_output_row) { "9781442214439|CIRNCRCP|123499" }
    it 'creates a single output line ' do
      pending("Combining MMS ID locations")
      expect("output_row").to eq(expected_output_row)
    end
  end
end
