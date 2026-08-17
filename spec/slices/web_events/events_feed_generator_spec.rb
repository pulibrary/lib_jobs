# frozen_string_literal: true
require 'rails_helper'

RSpec.describe WebEvents::EventsFeedGenerator do
  context 'when run at a particular time' do
    let(:run_time) { Time.zone.local(2022, 3, 14, 15, 9, 26) }
    before do
      allow(Time).to receive(:now).and_return(run_time)
    end
    it 'records that time in the database' do
      generator = described_class.new(create_csv: ->() { Success('tmp/my-file.csv') })
      generator.run
      expect(DataSet.order(:created_at).last.report_time).to eq(run_time)
    end
  end
  context 'when the process has already been run in the past hour' do
    let(:original_data_set) do
      FactoryBot.create(:data_set,
                                                category: 'EventsFeed',
                                                data_file: 'library_events_20221109.csv')
    end
    before do
      original_data_set.save
      allow(File).to receive(:exist?).and_return true
      allow(File).to receive(:mtime).and_return 1.minute.ago
    end

    it 'returns the existing dataset' do
      generator = described_class.new(create_csv: ->() { Success('tmp/my-file.csv') })
      expect { generator.run }.not_to change { DataSet.count }
    end
  end
end
