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

  it 'can tell if a call number is in range for the selector' do
    expect(subject.call_number_in_range_for_selector?(selector:)).to be false
  end

  it 'can parse the call number and constituent parts' do
    expect(subject.call_number).to eq('HD7123 .A22 no. 3')
    expect(subject.lc_class).to eq('HD')
    expect(subject.lc_number).to eq(7123)
  end

  it 'can tell if it is a juvenile work' do
    expect(subject.juvenile?).to be false
  end

  it 'can tell if it is an audiobook' do
    expect(subject.audiobook?).to be false
  end

  it 'has an array of subjects' do
    expect(subject.subjects).to match_array([" Unemployment insurance -- Great Britain", " Health insurance -- Great Britain"])
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

  it 'can give a string of languages' do
    expect(subject.languages).to eq('eng')
  end

  it 'can give an id' do
    expect(subject.oclc_id).to eq('ocm00414106')
  end

  it 'does not have an isbn' do
    expect(subject.isbns).to eq('')
  end

  it 'can give an id' do
    expect(subject.oclc_id).to eq('ocm00414106')
  end

  # it 'can go through all the records to find a relevant one' do
  #   marc_reader.each_with_index do |record, index|
  #     # byebug if described_class.new(marc_record: record).generally_relevant?
  #     byebug unless record['245'].try(:[], 'a')
  #     # record['035']['a'] == "(OCoLC)1389531111"
  #   end
  # end

  context 'with a relevant work' do
    let(:marc_record) do
      marc_reader.find { |record| record['035']['a'] == "(OCoLC)1389531111" }
    end

    it 'can tell if a record is relevant to the selector' do
      expect(subject.call_number_in_range_for_selector?(selector:)).to be true
      expect(subject.class_relevant_to_selector?(selector:)).to be true
      expect(subject.subject_relevant_to_selector?(selector:)).to be true
      expect(subject.relevant_to_selector?(selector:)).to be true
    end

    it 'can parse the call number and constituent parts' do
      expect(subject.call_number).to eq('U799 .O75')
      expect(subject.lc_class).to eq('U')
      expect(subject.lc_number).to eq(799)
    end

    it 'has needed metadata' do
      expect(subject.oclc_id).to eq('on1389531111')
      expect(subject.isbns).to eq('')
      expect(subject.lccns).to eq('2023214610')
      expect(subject.author).to eq('')
      expect(subject.title).to include('Oruzheĭnyĭ sbornik')
      expect(subject.f008_pub_place).to eq('ru')
      expect(subject.pub_place).to eq('Sankt-Peterburg ')
      expect(subject.pub_name).to eq("Izdatel'stvo Gosudarstvennogo Ėrmitazha")
      expect(subject.pub_date).to eq('2021-')
      expect(subject.description).to eq('volumes : illustrations ; 26 cm')
      expect(subject.format).to eq('as')
      expect(subject.languages).to eq('rus | eng')
      expect(subject.subject_string).to eq(" Gosudarstvennyĭ Ėrmitazh (Russia) -- Congresses |" \
        "  Weapons -- History -- Congresses |  Armor -- History -- Congresses |" \
        "  Weapons -- Museums -- Russia (Federation) -- Congresses |" \
        "  Armor -- Museums -- Russia (Federation) -- Congresses")
    end
  end

  context 'with a call number with a decimal' do
    let(:marc_record) do
      marc_reader.find { |record| record['035']['a'] == "(OCoLC)01036108" }
    end

    it 'can tell if a call number is relevant to the selector' do
      expect(subject.class_relevant_to_selector?(selector:)).to be true
      expect(subject.call_number_in_range_for_selector?(selector:)).to be false
    end

    it 'can parse the call number and constituent parts' do
      expect(subject.call_number).to eq('KBR27.5.I56 C38 1964')
      expect(subject.lc_class).to eq('KBR')
      expect(subject.lc_number).to eq(27.5)
    end

    it 'has needed metadata' do
      expect(subject.oclc_id).to eq('ocm01036108')
      expect(subject.isbns).to eq("9783700102915 | 9783700192114 | 9783700121749 | 9783700120131 | " \
        "9783700121961 | 9783700125501 | 9783700129967 | 9783700132769 | 9783700136842 | 9783700165446 " \
        "| 9783700171430 | 9783700176718 | 9783700181095 | 9783700187196 | 9783700105565")
      expect(subject.lccns).to eq('70230550')
      expect(subject.author).to eq('Catholic Church. Pope (1198-1216 : Innocent III)')
      expect(subject.title).to include("Die Register Innocenz' III")
      expect(subject.f008_pub_place).to eq('au')
      expect(subject.pub_place).to eq('Graz ;')
      expect(subject.pub_name).to eq('Hermann Böhlaus Nachf')
      expect(subject.pub_date).to eq('1964-1968')
      expect(subject.description).to eq('volumes <1, 2-3, 5-14>; 25 cm.')
      expect(subject.format).to eq('am')
      expect(subject.languages).to eq('ger | lat')
      expect(subject.subject_string).to eq(" Innocent III Pope 1160 or 1161-1216 |" \
        "  Church history -- 12th century -- Sources |" \
        "  Church history -- 13th century -- Sources |" \
        "  Papacy -- History -- To 1309 -- Sources |" \
        "  Canon law -- Sources")
    end
  end
end
