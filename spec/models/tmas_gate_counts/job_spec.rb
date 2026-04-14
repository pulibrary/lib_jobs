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
      next_date_class = class_double(NextDateToProcess, next: Some(Date.parse('2020-01-01')))
      fetch_tmas_counts = instance_double(TMASGateCounts::FetchTMASCounts, call: Success([]))
      fetch_tmas_counts_class = class_double(TMASGateCounts::FetchTMASCounts, new: fetch_tmas_counts)

      described_class.new(next_date_class:, fetch_tmas_counts_class:).run

      expect(fetch_tmas_counts).to have_received(:call).with(start_date: Date.parse('2020-01-01'))
    end

    it 'defaults to 2025-09-01 if it has not yet been run' do
      next_date_class = class_double(NextDateToProcess, next: None())
      fetch_tmas_counts = instance_double(TMASGateCounts::FetchTMASCounts, call: Success([]))
      fetch_tmas_counts_class = class_double(TMASGateCounts::FetchTMASCounts, new: fetch_tmas_counts)

      described_class.new(next_date_class:, fetch_tmas_counts_class:).run

      expect(fetch_tmas_counts).to have_received(:call).with(start_date: Date.parse('2025-09-01'))
    end
  end
end
