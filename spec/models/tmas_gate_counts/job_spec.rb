# frozen_string_literal: true
require 'rails_helper'

RSpec.describe TMASGateCounts::Job do
  include Dry::Monads[:maybe, :result]
  it 'has the correct category' do
    job = described_class.new
    expect(job.category).to eq 'TMASGateCounts'
  end
  describe '#run' do
    it 'fetches the tmas counts for the next unprocessed day through yesterday' do
      first_date_to_process = Date.parse('2020-01-01')
      next_date_class = class_double(NextDateToProcess, next: Some(first_date_to_process), set: true)
      fetch_tmas_counts = instance_double(TMASGateCounts::FetchTMASCounts)
      allow(fetch_tmas_counts).to receive(:call).and_yield(Success([]), first_date_to_process)
      fetch_tmas_counts_class = class_double(TMASGateCounts::FetchTMASCounts, new: fetch_tmas_counts)

      described_class.new(next_date_class:, fetch_tmas_counts_class:).run

      expect(fetch_tmas_counts).to have_received(:call).with(start_date: Date.parse('2020-01-01'))
    end

    it 'updates the next date to process after a successful run' do
      first_date_to_process = Date.parse('2020-01-01')
      next_date_class = class_double(NextDateToProcess, next: Some(first_date_to_process), set: true)
      fetch_tmas_counts = instance_double(TMASGateCounts::FetchTMASCounts)
      allow(fetch_tmas_counts).to receive(:call).and_yield(Success([]), first_date_to_process)
      fetch_tmas_counts_class = class_double(TMASGateCounts::FetchTMASCounts, new: fetch_tmas_counts)

      described_class.new(next_date_class:, fetch_tmas_counts_class:).run

      expect(next_date_class).to have_received(:set).with(job: 'TMASGateCounts', next: Date.parse('2020-01-02'))
    end

    it 'defaults to 2025-09-01 if it has not yet been run' do
      first_date_to_process = Date.parse('2025-09-01')
      next_date_class = class_double(NextDateToProcess, next: None(), set: true)
      fetch_tmas_counts = instance_double(TMASGateCounts::FetchTMASCounts)
      allow(fetch_tmas_counts).to receive(:call).and_yield(Success([]), first_date_to_process)
      fetch_tmas_counts_class = class_double(TMASGateCounts::FetchTMASCounts, new: fetch_tmas_counts)

      described_class.new(next_date_class:, fetch_tmas_counts_class:).run

      expect(fetch_tmas_counts).to have_received(:call).with(start_date: Date.parse('2025-09-01'))
    end
  end
end
