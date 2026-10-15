# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WebDatabaseList::DatabaseToCSV do
  let(:databases) do
    database_to_csv = described_class.new
    fixtures = JSON.parse(File.read(file_fixture('libguides_databases.json')))
    fixtures.map { |fixture| database_to_csv.call fixture }
  end

  describe '#initialize' do
    it 'retrieves the id from the provided json' do
      expect(databases.first.fetch(:id)).to eq('2938715')
    end

    it 'retrieves the name from the provided json' do
      expect(databases.first.fetch(:name)).to eq('Africa Knowledge Project')
    end

    it 'retrieves the description from the provided json' do
      expect(databases.second.fetch(:description))
        .to eq('Free index to articles on a wide range of topics relating to all countries in Africa.   Some of the databases included are: ' \
               'Africana Periodical Literature, African Women\'s literature, Women Travelers, Explorers and Missionaries to Africa, AJOL,  ' \
               'and the Library of Congress’s Quarterly Index of African Periodical Literature.  Searchable by region, country, subject categories, and by keyword.')
    end

    it 'retrieves the alt_names, if present, from the provided json' do
      expect(databases.first.fetch(:alt_names)).to be_nil
      expect(databases.last.fetch(:alt_names)).to eq('Deutsche Literatur des 18. Jahrhunderts Online; Eighteenth Century German Literature Online')
    end

    it 'retrieves the url from the provided json' do
      expect(databases.third.fetch(:url)).to eq('http://aabd.chadwyck.com/')
    end

    it 'retrieves the friendly_url, if present, from the provided json' do
      expect(databases.fourth.fetch(:friendly_url)).to be_nil
      expect(databases.last.fetch(:friendly_url)).to eq('https://libguides.princeton.edu/resource/4856')
    end

    it 'retrieves the subjects and concatenates them into a string' do
      expect(databases.second.fetch(:subjects)).to eq('African Studies')
      expect(databases.third.fetch(:subjects)).to eq('African American Studies;Biographical Sources')
      expect(databases.fourth.fetch(:subjects)).to eq('')
    end
  end

  describe '#to_csv_row' do
    it 'creates a CSV::Row with the correct content' do
      expect(databases.second).to eq(
        CSV::Row.new(
          %i[id name description alt_names url friendly_url subjects],
          ['2938717',
           'AfricaBib.org: Africana Periodical Literature',
           'Free index to articles on a wide range of topics relating to all countries in Africa.   Some of the databases included ' \
           'are: Africana Periodical Literature, African Women\'s literature, Women Travelers, Explorers and Missionaries to Africa, ' \
           'AJOL,  and the Library of Congress’s Quarterly Index of African Periodical Literature.  Searchable by region, country, subject ' \
           'categories, and by keyword.',
           nil,
           'http://www.africabib.org/perio.htm',
           'https://libguides.princeton.edu/resource/11553',
           'African Studies']
        )
      )
    end
  end
end
