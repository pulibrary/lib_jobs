# frozen_string_literal: true
require 'rails_helper'

RSpec.describe WebDatabaseList::Database, type: :model do
  let(:databases) do
    fixtures = JSON.parse(File.read(file_fixture('libguides_databases.json')))
    fixtures.map { |fixture| described_class.new fixture }
  end

  describe '#initialize' do
    it 'retrieves the id from the provided json' do
      expect(databases.first.id).to eq('2938715')
    end
    it 'retrieves the name from the provided json' do
      expect(databases.first.name).to eq('Africa Knowledge Project')
    end
    it 'retrieves the description from the provided json' do
      expect(databases.second.description).to eq('Free index to articles on a wide range of topics relating to all countries in Africa.   Some of the databases included are: '\
        'Africana Periodical Literature, African Women\'s literature, Women Travelers, Explorers and Missionaries to Africa, AJOL,  '\
        'and the Library of Congress’s Quarterly Index of African Periodical Literature.  Searchable by region, country, subject categories, and by keyword.')
    end
    it 'retrieves the alt_names, if present, from the provided json' do
      expect(databases.first.alt_names).to eq(nil)
      expect(databases.fifth.alt_names).to eq('Deutsche Literatur des 18. Jahrhunderts Online; Eighteenth Century German Literature Online')
    end
    it 'retrieves the url from the provided json' do
      expect(databases.third.url).to eq('http://aabd.chadwyck.com/')
    end
    it 'retrieves the friendly_url, if present, from the provided json' do
      expect(databases.fourth.friendly_url).to eq(nil)
      expect(databases.fifth.friendly_url).to eq('https://libguides.princeton.edu/resource/4856')
    end
    it 'retrieves the subjects and concatenates them into a string' do
      expect(databases.second.subjects).to eq('African Studies')
      expect(databases.third.subjects).to eq('African American Studies;Biographical Sources')
      expect(databases.fourth.subjects).to eq('')
    end
    describe '#resource_page_url' do
      it 'generates a resource page url from the title' do
        expect(databases.first.resource_page_url).to eq('https://libguides.princeton.edu/az/africa-knowledge-project')
      end

      it 'removes non A-Z/0-9 characters' do
        expect(databases.second.resource_page_url).to eq('https://libguides.princeton.edu/az/africabiborg-africana-periodical-literature')
      end

      it 'only uses the first part of title with translations' do
        expect(databases.fifth.resource_page_url).to eq('https://libguides.princeton.edu/az/18th-century-german-literature-online')
      end

      it 'uses unaccented characters' do
        pending('libguides making sense-it randomly removes a word from the title')
        expect(databases[5].resource_page_url).to eq('https://libguides.princeton.edu/az/choson-ollon-kiji')
      end
    end
  end

  describe '#to_csv_row' do
    it 'creates a CSV::Row with the correct content' do
      expect(databases.second.to_csv_row).to eq(
        CSV::Row.new(
          [:id, :name, :description, :alt_names, :url, :friendly_url, :subjects, :resource_page_url],
          ['2938717',
           'AfricaBib.org: Africana Periodical Literature',
           'Free index to articles on a wide range of topics relating to all countries in Africa.   Some of the databases included '\
           'are: Africana Periodical Literature, African Women\'s literature, Women Travelers, Explorers and Missionaries to Africa, '\
           'AJOL,  and the Library of Congress’s Quarterly Index of African Periodical Literature.  Searchable by region, country, subject '\
           'categories, and by keyword.',
           nil,
           'http://www.africabib.org/perio.htm',
           'https://libguides.princeton.edu/resource/11553',
           'African Studies',
           'https://libguides.princeton.edu/az/africabiborg-africana-periodical-literature']
        )
      )
    end
  end
end
