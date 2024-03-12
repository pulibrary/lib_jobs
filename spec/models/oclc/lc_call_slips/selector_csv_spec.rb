# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Oclc::SelectorCSV, type: :model, newly_cataloged: true do
  let(:subject) { described_class.new(selector_config:) }
  let(:new_csv_path_string) { 'spec/fixtures/oclc/2023-07-12-newly-cataloged-by-lc-bordelon.csv' }
  let(:new_csv_path_1) { Rails.root.join('spec', 'fixtures', 'oclc', '2023-07-12-newly-cataloged-by-lc-bordelon.csv') }
  let(:new_csv_path_2) { Rails.root.join('spec', 'fixtures', 'oclc', '2023-07-12-newly-cataloged-by-lc-darrington.csv') }
  let(:freeze_time) { Time.utc(2023, 7, 12) }
  let(:selector_config) { Rails.application.config.newly_cataloged.selectors.first }
  let(:headers) do
    ['OCLC Number', 'ISBNs', 'LCCNs', 'Author', 'Title', '008 Place Code',
     'Pub Place', 'Pub Name', 'Pub Date', 'Description', 'Format', 'Languages',
     'Call Number', 'Subjects', 'Non-Romanized Title']
  end

  around do |example|
    File.delete(new_csv_path_1) if File.exist?(new_csv_path_1)
    File.delete(new_csv_path_2) if File.exist?(new_csv_path_2)
    Timecop.freeze(freeze_time) do
      example.run
    end
    File.delete(new_csv_path_1) if File.exist?(new_csv_path_1)
    File.delete(new_csv_path_2) if File.exist?(new_csv_path_2)
  end

  it 'can be instantiated' do
    expect(described_class.new(selector_config:)).to be
  end

  it 'has expected values' do
    expect(subject.selector.name).to eq('bordelon')
    expect(subject.csv_file_path).to eq('spec/fixtures/oclc/')
    expect(subject.file_path).to eq new_csv_path_string
  end

  it 'creates a csv file for a selector' do
    expect(File.exist?(new_csv_path_1)).to be false
    subject.create
    expect(File.exist?(new_csv_path_1)).to be true
  end

  it 'adds headers to the CSV' do
    subject.create
    csv_file = CSV.read(new_csv_path_1, encoding: "bom|utf-8")
    expect(csv_file[0]).to eq(headers)
  end
end
