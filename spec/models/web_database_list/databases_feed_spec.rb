# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WebDatabaseList::DatabasesFeed, type: :model do
  describe('CSV file generation') do
    let(:filename) { Pathname.new(Rails.root.join('tmp', "databases.csv")) }
    let(:first_row) do
      ['2938715',
       'Africa Knowledge Project',
       'Provides access to these journals: JENDa : a journal of culture and African women studies; West Africa review; ProudFlesh : new Afrikan journal of culture, '\
       'politics and consciousness; Ijele : art ejournal of the African world ; African journal of criminology and justice studies and Journal of African philosophy; '\
       'and the following databases: Kiswahili story database; African music database and the Biafran War database : Africa\'s first modern genocide (1967-1970)',
       nil,
       'http://www.africaknowledgeproject.org',
       'https://libguides.princeton.edu/resource/5014',
       'African Studies']
    end
    let(:feed) do
      database_list = JSON.parse(File.read(file_fixture('libguides_databases.json')))
      described_class.new(database_list:, filename:)
    end

    around do |example|
      File.delete(filename) if File.exist?(filename)
      example.run
      File.delete(filename) if File.exist?(filename)
    end

    it 'creates a CSV file' do
      feed.run
      expect(File.exist?(filename)).to be true
    end

    it 'the CSV file has a header row and one row for each database' do
      feed.run
      expect(CSV.read(filename).length).to eq(5)
    end

    it 'the first row of data is correct' do
      feed.run
      expect(CSV.read(filename).second).to eq(first_row)
    end

    it 'skips rows that do not have a friendly_url' do
      feed.run
      records = CSV.read(filename)
      expect(records.select { |record| record.include?("African American Song") }).to be_empty
    end

    it 'logs skipped rows' do
      allow(Rails.logger).to receive(:warn)
      feed.run
      expect(Rails.logger).to have_received(:warn).once.with("Skipping database without friendly_url. Database id: 2938725, Database name: African American Song")
    end

    context 'when run at a particular time' do
      let(:run_time) { Time.zone.local(2022, 3, 14, 15, 9, 26) }
      before do
        allow(Time).to receive(:now).and_return(run_time)
      end
      it 'records that time in the database' do
        feed.run
        expect(DataSet.order('created_at').last.report_time).to eq(run_time)
      end
    end

    context 'when the process has already been run in the past 2 hours' do
      let(:original_data_set) do
        FactoryBot.create(:data_set,
                          category: 'DatabasesFeed',
                          data_file: 'library_databases_20221109.csv')
      end
      before do
        original_data_set.save
        allow(File).to receive(:exist?).and_return true
        allow(File).to receive(:mtime).and_return 1.minute.ago
      end

      it 'returns the existing dataset' do
        expect { feed.run }.not_to change { DataSet.count }
      end
    end
  end
end
