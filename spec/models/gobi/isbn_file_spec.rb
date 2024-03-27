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
    expect(csv_file.length).to eq(196)
    first_row = csv_file[0]
    expect(first_row[0]).to eq('9789775414656')
    expect(first_row[1]).to eq('RCP')
    expect(first_row[2]).to eq('123499')
  end

  describe 'bib_hash' do
    let(:headers) { ['MMS Id', 'Begin Publication Date', 'ISBN Valid', 'Library Code', 'Location Code'] }
    let(:row_one) { CSV::Row.new(headers, fields_one) }
    let(:row_two) { CSV::Row.new(headers, fields_two) }

    context 'with the same bib id and one isbn' do
      let(:fields_one) { ['99113270853506421', '2019', '1442214430; 9781442214439', 'recap', 'pa'] }
      let(:fields_two) { ['99113270853506421', '2019', '1442214430; 9781442214439', 'firestone', 'stacks'] }
      before do
        isbn_file.build_bib_hash(row: row_one)
        isbn_file.build_bib_hash(row: row_two)
      end
      it 'creates a hash of all bib ids and accumulates associated data' do
        expect(isbn_file.bib_hash).to eq({ "99113270853506421" => {
                                           "isbns": ["9781442214439"],
                                           "loc_combos": ['recap$pa', 'firestone$stacks']
                                         } })
      end
      it 'writes the bib_hash to a CSV file' do
        isbn_file.write_bib_hash_to_csv
        csv_file = CSV.read(new_csv_path, col_sep: "|")
        expect(csv_file.length).to eq(1)
      end
      it 'writes the expected string to a CSV file' do
        isbn_file.write_bib_hash_to_csv
        csv_file = File.read(new_csv_path)
        expect(csv_file).to eq("9781442214439|CirRCP|123499\n")
      end
    end
    context 'with the same bib id and multiple isbns' do
      let(:fields_one) { ['99113270853506421', '2019', '0195103483; 9780195103489; 0195103491; 9780195103496', 'recap', 'pa'] }
      let(:fields_two) { ['99113270853506421', '2019', '0195103483; 9780195103489; 0195103491; 9780195103496', 'firestone', 'stacks'] }

      it 'creates a hash of all bib ids and accumulates associated data' do
        isbn_file.build_bib_hash(row: row_one)
        isbn_file.build_bib_hash(row: row_two)
        expect(isbn_file.bib_hash).to eq({ "99113270853506421" => {
                                           "isbns": ["9780195103489", "9780195103496"],
                                           "loc_combos": ['recap$pa', 'firestone$stacks']
                                         } })
      end
      it 'writes the bib_hash to a CSV file' do
        isbn_file.build_bib_hash(row: row_one)
        isbn_file.build_bib_hash(row: row_two)
        isbn_file.write_bib_hash_to_csv
        csv_file = CSV.read(new_csv_path, col_sep: "|")
        expect(csv_file.length).to eq(2)
      end
    end
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
      expect(isbn_file.code_string(loc_combos: ['arch$ref'])).to eq('NC')
    end
    it 'has a code string of RCP when in a shared location' do
      expect(isbn_file.code_string(loc_combos: ['recap$pa'])).to eq('RCP')
    end
    it 'has a code string of Cir for all other locations' do
      expect(isbn_file.code_string(loc_combos: ['anything$atall'])).to eq('Cir')
    end
    it 'combines codes for multiple locations' do
      expect(isbn_file.code_string(loc_combos: ['arch$ref', 'recap$pa'])).to eq('NCRCP')
    end
    it 'keeps the same code order no matter the order of locations' do
      expect(isbn_file.code_string(loc_combos: ['arch$ref', 'any$thing', 'recap$pa'])).to eq('CirNCRCP')
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
    it 'removes ten digit isbns that match a 13 digit isbn' do
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

  describe '#convert_isbn' do
    it 'converts a ten digit isbn to a thirteen digit isbn' do
      expect(isbn_file.convert_to_isbn_thirteen(isbn: '0195103483')).to eq('9780195103489')
      expect(isbn_file.convert_to_isbn_thirteen(isbn: '0195103491')).to eq('9780195103496')
      expect(isbn_file.convert_to_isbn_thirteen(isbn: '9642523299')).to eq('9789642523290')
      expect(isbn_file.convert_to_isbn_thirteen(isbn: '6411053861')).to eq('9786411053866')
    end
  end
end
