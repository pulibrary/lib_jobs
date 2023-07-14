# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Oclc::Record, type: :model do
  let(:oclc_fixture_file_path) { Rails.root.join('spec', 'fixtures', 'oclc', 'metacoll.PUL.new.D20230706.T213019.MZallDLC.1.mrc') }
  let(:marc_record) { marc_reader.first }
  let(:marc_reader) { MARC::Reader.new(oclc_fixture_file_path.to_s) }
  let(:selector_config) { Rails.application.config.newly_cataloged.selectors.first }
  let(:selector) { Oclc::Selector.new(selector_config:) }
  let(:subject) { described_class.new(marc_record:) }
  it 'can be instantiated' do
    expect(described_class.new(marc_record:)).to be
  end

  it 'can tell if a record is generally relevant' do
    expect(subject.generally_relevant?).to be false
  end

  it 'can tell if a record is relevant to the selector' do
    expect(subject.relevant_to_selector?(selector:)).to be false
  end

  it 'can tell if a class is relevant to the selector' do
    expect(subject.class_relevant_to_selector?(selector:)).to be false
  end

  it 'can tell if a subject is relevant to the selector' do
    expect(subject.subject_relevant_to_selector?(selector:)).to be false
  end

  it 'has an lc class' do
    expect(subject.lc_class).to eq('HD')
  end

  it 'can tell if it is a juvenile work' do
    expect(subject.juvenile?).to be false
  end

  it 'can tell if it is an audiobook' do
    expect(subject.audiobook?).to be false
  end

  it 'has an array of subjects' do
    expect(subject.subjects).to match_array(["Great Britain", "Health insurance", "Unemployment insurance"])
  end

  it 'can tell if it was published within the last two years' do
    expect(subject.within_last_two_years?).to eq(false)
  end

  it 'can tell if it is a computer file' do
    expect(subject.computer_file?).to eq(true)
  end

  it 'can tell if it was published in the US, UK, or Canada' do
    expect(subject.published_in_us_uk_or_canada?).to be true
  end

  it 'can give an array of languages' do
    expect(subject.languages).to match_array(['eng'])
  end

  # it 'can go through all the records to find a relevant one' do
  #   marc_reader.each_with_index do |record, index|
  #     byebug if described_class.new(marc_record: record).generally_relevant?
  #     # record['035']['a'] == "(OCoLC)1389531111"
  #   end
  # end

  context 'with a relevant work' do
    let(:marc_record) do
      marc_reader.find { |record| record['035']['a'] == "(OCoLC)1389531111" }
    end

    it 'can tell if a record is relevant to the selector' do
      expect(subject.class_relevant_to_selector?(selector:)).to be true
      expect(subject.subject_relevant_to_selector?(selector:)).to be true
      expect(subject.relevant_to_selector?(selector:)).to be true
    end
  end
end
