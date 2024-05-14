# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Oclc::LcCallSlips::Record, type: :model, lc_call_slips: true do
  let(:marc_record) { marc_reader.first }
  let(:marc_reader) { MARC::Reader.new(oclc_fixture_file_path.to_s, external_encoding: 'UTF-8') }
  let(:selector_config) do
    { bordelon: {
      classes: [{ class: 'G', low_num: 154.9, high_num: 155.8 },
                { class: 'HD', low_num: 0, high_num: 99_999 }],
      subjects: ['economic aspects']
    } }
  end
  let(:selector) { Oclc::LcCallSlips::Selector.new(selector_config:) }
  let(:oclc_record) { described_class.new(marc_record:) }

  describe 'subjects' do
    let(:marc_record) { MARC::Record.new_from_hash('fields' => fields) }
    let(:fields) do
      [
        { '008' => '120627s2024    ncuabg  ob    001 0 gre d' },
        { '650' => { "ind1" => "",
                     "ind2" => "0",
                     'subfields' => [
                       { 'a' => 'Emigration and immigration',
                         'z' => 'Statistics' }
                     ] } }
      ]
    end
    context 'with a selector with a multi-part subject term' do
      let(:selector_config) do
        { donatiello: {
          subjects: ['census',
                     'statistics, vital',
                     'emigration and immigration -- statistics',
                     'statistics, medical']
        } }
      end

      it 'recognizes that it is relevant' do
        expect(oclc_record.subject_relevant_to_selector?(selector:)).to eq(true)
      end
    end
    context 'with a selector without any subjects' do
      let(:selector_config) do
        { hatfield: {
          classes: [{ class: 'PN', low_num: 6755, high_num: 6758 }]
        } }
      end
      it 'does not mark a record as relevant based on its subjects' do
        expect(oclc_record.subject_relevant_to_selector?(selector:)).to eq(false)
        expect(oclc_record.relevant_to_selector?(selector:)).to eq(false)
      end
    end
    context 'with capitalization in the config file subjects' do
      let(:selector_config) do
        { hatfield: {
          classes: [{ class: 'X', low_num: 0, high_num: 99_999 }],
          subjects: ['Judaism']
        } }
      end
      let(:fields) do
        [
          { '008' => '120627s2024    gerabg  ob    001 0 gre d' },
          { '650' => { "ind1" => "",
                       "ind2" => "0",
                       'subfields' => [
                         { 'a' => 'Judaism' }
                       ] } }
        ]
      end

      it 'uses case insensitive matching' do
        expect(oclc_record.subject_relevant_to_selector?(selector:)).to eq(true)
        expect(oclc_record.relevant_to_selector?(selector:)).to eq(true)
      end
    end
  end

  describe 'call number parsing' do
    let(:marc_record) { MARC::Record.new_from_hash('fields' => fields) }

    context 'with a call number with just a class' do
      let(:fields) do
        [{ '050' => { 'indicator1' => ' ',
                      'indicator2' => ' ',
                      'subfields' => [{ 'a' => 'HD' }] } }]
      end
      it 'has a zero lc_number' do
        expect(oclc_record.call_number).to eq('HD')
        expect(oclc_record.lc_class).to eq('HD')
        expect(oclc_record.lc_number).to be 0.0
        expect(oclc_record.call_number_in_range_for_selector?(selector:)).to be true
      end
    end

    context 'with a call number with decimals in it' do
      context 'in range' do
        let(:fields) do
          [
            { '050' => { 'indicator1' => ' ',
                         'indicator2' => ' ',
                         'subfields' => [{ 'a' => 'G155.8', 'b' => '.C6 H83 2015' }] } }
          ]
        end

        it 'has that the call number is in range for the selector' do
          expect(oclc_record.call_number).to eq('G155.8 .C6 H83 2015')
          expect(oclc_record.lc_class).to eq('G')
          expect(oclc_record.lc_number).to be 155.8
          expect(oclc_record.call_number_in_range_for_selector?(selector:)).to be true
        end
      end
      context 'out of range' do
        let(:fields) do
          [
            { '050' => { 'indicator1' => ' ',
                         'indicator2' => ' ',
                         'subfields' => [{ 'a' => 'G155.9', 'b' => '.C6 H83 2015' }] } }
          ]
        end

        it 'has that the call number is out of range for selector' do
          expect(oclc_record.call_number).to eq('G155.9 .C6 H83 2015')
          expect(oclc_record.lc_class).to eq('G')
          expect(oclc_record.lc_number).to be 155.9
          expect(oclc_record.call_number_in_range_for_selector?(selector:)).to be false
        end
      end
    end
    context 'with a selector with a single call number, not a range' do
      let(:selector_config) do
        { donatiello: {
          classes: [{ class: 'RA', low_num: 407.3, high_num: 407.3 }]
        } }
      end
      context 'with a matching call number' do
        let(:fields) do
          [
            { '050' => { 'indicator1' => ' ',
                         'indicator2' => ' ',
                         'subfields' => [{ 'a' => 'RA407.3' }] } }
          ]
        end
        it 'recognizes that it is relevant' do
          expect(oclc_record.call_number_in_range_for_selector?(selector:)).to eq(true)
        end
      end
      context 'with an almost-matching call number' do
        let(:fields) do
          [
            { '050' => { 'indicator1' => ' ',
                         'indicator2' => ' ',
                         'subfields' => [{ 'a' => 'RA407' }] } }
          ]
        end
        it 'recognizes that it is not relevant' do
          expect(oclc_record.call_number_in_range_for_selector?(selector:)).to eq(false)
        end
      end
    end
    context 'with a three letter class' do
      let(:selector_config) do
        { hatfield: {
          classes: [{ class: 'KBM', low_num: 0, high_num: 99_999 }]
        } }
      end
      let(:fields) do
        [
          { '050' => { 'indicator1' => ' ',
                       'indicator2' => ' ',
                       'subfields' => [{ 'a' => 'KBM520.2', 'b' => '.B54 2015' }] } }
        ]
      end
      it 'recognizes that it is relevant' do
        expect(oclc_record.call_number_in_range_for_selector?(selector:)).to eq(true)
      end
    end
  end

  context 'fixture one' do
    let(:oclc_fixture_file_path) { Rails.root.join('spec', 'fixtures', 'oclc', 'metacoll.PUL.new.D20230718.T213016.MZallDLC.1.mrc') }

    context 'with relevant record 1' do
      let(:marc_record) do
        marc_reader.find { |record| record['001'].value.strip == "on1390709398" }
      end

      it 'can tell that the record is generally relevant' do
        expect(oclc_record.juvenile?).to eq(false)
        expect(oclc_record.audiobook?).to eq(false)
        expect(oclc_record.published_in_us_uk_or_canada?).to eq(false)
        expect(oclc_record.monograph?).to eq(true)
        expect(oclc_record.within_last_two_years?).to eq(true)
        expect(oclc_record.generally_relevant?).to eq(true)
        expect(oclc_record.relevant_to_selector?(selector:)).to eq(true)
      end
    end

    context 'with relevant record 2' do
      let(:marc_record) do
        marc_reader.find { |record| record['001'].value.strip == "on1390704802" }
      end

      it 'can tell that the record is relevant' do
        expect(oclc_record.juvenile?).to eq(false)
        expect(oclc_record.audiobook?).to eq(false)
        expect(oclc_record.published_in_us_uk_or_canada?).to eq(false)
        expect(oclc_record.monograph?).to eq(true)
        expect(oclc_record.within_last_two_years?).to eq(true)
        expect(oclc_record.generally_relevant?).to eq(true)
        expect(oclc_record.call_number_in_range_for_selector?(selector:)).to eq(true)
        expect(oclc_record.relevant_to_selector?(selector:)).to eq(true)
      end
    end
  end

  context 'fixture two' do
    let(:oclc_fixture_file_path) { Rails.root.join('spec', 'fixtures', 'oclc', 'metacoll.PUL.new.D20230706.T213019.MZallDLC.1.mrc') }

    it 'can be instantiated' do
      expect(described_class.new(marc_record:)).to be
    end

    it 'can tell if a record is generally relevant' do
      expect(oclc_record.generally_relevant?).to be false
    end

    it 'can tell if a record is relevant to the selector' do
      expect(oclc_record.relevant_to_selector?(selector:)).to be false
    end

    it 'can tell if a class is relevant to the selector' do
      expect(oclc_record.lc_class).to eq('HD')
      expect(oclc_record.class_relevant_to_selector?(selector:)).to be true
    end

    it 'can tell if a subject is relevant to the selector' do
      expect(oclc_record.subject_relevant_to_selector?(selector:)).to be false
    end

    it 'can tell if a call number is in range for the selector' do
      expect(oclc_record.call_number).to eq('HD7123 .A22 no. 3')
      expect(oclc_record.call_number_in_range_for_selector?(selector:)).to be true
    end

    it 'can parse the call number and constituent parts' do
      expect(oclc_record.call_number).to eq('HD7123 .A22 no. 3')
      expect(oclc_record.lc_class).to eq('HD')
      expect(oclc_record.lc_number).to eq(7123)
    end

    it 'can tell if it is a juvenile work' do
      expect(oclc_record.juvenile?).to be false
    end

    it 'can tell if it is an audiobook' do
      expect(oclc_record.audiobook?).to be false
    end

    it 'has an array of subjects' do
      expect(oclc_record.subjects).to match_array(["Unemployment insurance -- Great Britain", "Health insurance -- Great Britain"])
    end

    it 'can tell if it was published within the last two years' do
      expect(oclc_record.within_last_two_years?).to eq(false)
    end

    it 'can tell if it is a monograph file' do
      expect(oclc_record.monograph?).to eq(true)
    end

    it 'can tell if it was published in the US, UK, or Canada' do
      expect(oclc_record.published_in_us_uk_or_canada?).to be true
    end

    it 'can give a string of languages' do
      expect(oclc_record.languages).to eq('eng')
    end

    it 'can give an id' do
      expect(oclc_record.oclc_id).to eq('ocm00414106')
    end

    it 'does not have an isbn' do
      expect(oclc_record.isbns).to eq('')
    end

    it 'can give an id' do
      expect(oclc_record.oclc_id).to eq('ocm00414106')
    end

    context 'with a relevant work' do
      let(:marc_record) do
        marc_reader.find { |record| record['035']['a'] == "(OCoLC)1389531111" }
      end

      it 'can tell if a record is relevant to the selector' do
        expect(oclc_record.call_number).to eq('U799 .O75')
        expect(oclc_record.call_number_in_range_for_selector?(selector:)).to be false
        expect(oclc_record.class_relevant_to_selector?(selector:)).to be false
        expect(oclc_record.subject_relevant_to_selector?(selector:)).to be false
        expect(oclc_record.relevant_to_selector?(selector:)).to be false
      end

      it 'can parse the call number and constituent parts' do
        expect(oclc_record.call_number).to eq('U799 .O75')
        expect(oclc_record.lc_class).to eq('U')
        expect(oclc_record.lc_number).to eq(799)
      end

      it 'has needed metadata' do
        expect(oclc_record.oclc_id).to eq('on1389531111')
        expect(oclc_record.isbns).to eq('')
        expect(oclc_record.lccns).to eq('2023214610')
        expect(oclc_record.author).to eq('')
        expect(oclc_record.title).to include('Oruzheĭnyĭ sbornik')
        expect(oclc_record.non_romanized_title).to include('Оружейный сборник')
        expect(oclc_record.f008_pub_place).to eq('ru')
        expect(oclc_record.pub_place).to eq('Sankt-Peterburg')
        expect(oclc_record.pub_name).to eq("Izdatel'stvo Gosudarstvennogo Ėrmitazha")
        expect(oclc_record.pub_date).to eq('2021-')
        expect(oclc_record.description).to eq('volumes : illustrations ; 26 cm')
        expect(oclc_record.format).to eq('as')
        expect(oclc_record.languages).to eq('rus | eng')
        expect(oclc_record.subject_string).to eq("Gosudarstvennyĭ Ėrmitazh (Russia) -- Congresses |" \
          " Weapons -- History -- Congresses | Armor -- History -- Congresses |" \
          " Weapons -- Museums -- Russia (Federation) -- Congresses |" \
          " Armor -- Museums -- Russia (Federation) -- Congresses")
      end
    end

    context 'with a call number with a decimal' do
      let(:marc_record) do
        marc_reader.find { |record| record['035']['a'] == "(OCoLC)01036108" }
      end

      it 'can tell if a call number is relevant to the selector' do
        expect(oclc_record.lc_class).to eq('KBR')
        expect(oclc_record.class_relevant_to_selector?(selector:)).to be false
        expect(oclc_record.call_number_in_range_for_selector?(selector:)).to be false
      end

      it 'can parse the call number and constituent parts' do
        expect(oclc_record.call_number).to eq('KBR27.5.I56 C38 1964')
        expect(oclc_record.lc_class).to eq('KBR')
        expect(oclc_record.lc_number).to eq(27.5)
      end

      it 'has needed metadata' do
        expect(oclc_record.oclc_id).to eq('ocm01036108')
        expect(oclc_record.isbns).to eq("9783700102915 | 9783700192114 | 9783700121749 | 9783700120131 | " \
          "9783700121961 | 9783700125501 | 9783700129967 | 9783700132769 | 9783700136842 | 9783700165446 " \
          "| 9783700171430 | 9783700176718 | 9783700181095 | 9783700187196 | 9783700105565")
        expect(oclc_record.lccns).to eq('70230550')
        expect(oclc_record.author).to eq('Catholic Church Pope (1198-1216 : Innocent III)')
        expect(oclc_record.title).to include("Die Register Innocenz' III")
        expect(oclc_record.non_romanized_title).to eq('')
        expect(oclc_record.f008_pub_place).to eq('au')
        expect(oclc_record.pub_place).to eq('Graz ;')
        expect(oclc_record.pub_name).to eq('Hermann Böhlaus Nachf.')
        expect(oclc_record.pub_date).to eq('1964-1968')
        expect(oclc_record.description).to eq('volumes <1, 2-3, 5-14>; 25 cm.')
        expect(oclc_record.format).to eq('am')
        expect(oclc_record.languages).to eq('ger | lat')
        expect(oclc_record.subject_string).to eq("Innocent III, Pope, 1160 or 1161-1216 |" \
          " Church history -- 12th century -- Sources |" \
          " Church history -- 13th century -- Sources |" \
          " Papacy -- History -- To 1309 -- Sources |" \
          " Canon law -- Sources")
      end
    end
  end

  context 'a selector who wants US, UK, and Canada publications' do
    let(:selector_config) do
      { hollander: {
        classes: [{ class: 'G', low_num: 154.9, high_num: 155.8 },
                  { class: 'HD', low_num: 0, high_num: 99_999 }],
        subjects: ['Judaism'],
        include_us_uk_canada: true
      } }
    end
    let(:marc_record) { MARC::Record.new_from_hash('fields' => fields, 'leader' => leader) }
    let(:fields) do
      [
        { '008' => '120627s2024    ncuabg  ob    001 0 gre d' },
        { '650' => { "ind1" => "",
                     "ind2" => "0",
                     'subfields' => [
                       { 'a' => 'Judaism' }
                     ] } }
      ]
    end
    let(:leader) { '00852cam a2200277 i 4500' }
    it 'recognizes that the record is relevant to the selector' do
      expect(oclc_record.published_in_us_uk_or_canada?).to eq(true)
      expect(oclc_record.subject_relevant_to_selector?(selector:)).to eq(true)
      expect(oclc_record.location_relevant_to_selector?(selector:)).to eq(true)
      expect(oclc_record.relevant_to_selector?(selector:)).to eq(true)
    end
    it 'recognizes that the record is generally relevant' do
      expect(oclc_record.monograph?).to eq(true)
      expect(oclc_record.within_last_two_years?).to eq(true)
      expect(oclc_record.juvenile?).to eq(false)
      expect(oclc_record.audiobook?).to eq(false)
      expect(oclc_record.generally_relevant?).to eq(true)
    end
  end

  describe 'keywords' do
    let(:marc_record) { MARC::Record.new_from_hash('fields' => fields) }
    let(:fields) do
      [
        { '008' => '120627s2024    gerabg  ob    001 0 gre d' },
        { '245' => { "ind1" => "1",
                     "ind2" => "0",
                     'subfields' => [
                       { 'a' => 'Chinese homestyle : ',
                         'b' => 'everyday plant-based recipes for takeout, dim sum, noodles, and more / ',
                         'c' => 'Maggie Zhu.' }
                     ] } }
      ]
    end
    context 'with a selector with a keyword' do
      let(:selector_config) do
        { heijdra: {
          keywords: ['chinese']
        } }
      end

      it 'recognizes that it is relevant' do
        expect(oclc_record.keywords_relevant_to_selector?(selector:)).to eq(true)
      end
    end
    context 'with a selector without any keywords' do
      let(:selector_config) do
        { hatfield: {
          classes: [{ class: 'PN', low_num: 6755, high_num: 6758 }]
        } }
      end
      it 'does not mark a record as relevant based on its subjects' do
        expect(oclc_record.keywords_relevant_to_selector?(selector:)).to eq(false)
        expect(oclc_record.relevant_to_selector?(selector:)).to eq(false)
      end
    end
    context 'with wildcard in the config file keywords' do
      let(:selector_config) do
        { heijdra: {
          keywords: ['chin*']
        } }
      end

      it 'matches using the wildcard' do
        expect(oclc_record.keywords_relevant_to_selector?(selector:)).to eq(true)
      end

      context 'keyword in record contains configured keyword, but config does not have wildcard at beginning and end' do
        let(:fields) do
          [
            { '008' => '120627s2024    gerabg  ob    001 0 gre d' },
            { '245' => { "ind1" => "1",
                         "ind2" => "0",
                         'subfields' => [
                           { 'a' => 'Machine learning : ' }
                         ] } }
          ]
        end
        it 'does not mark a record as relevant based on its subjects' do
          expect(oclc_record.keywords_relevant_to_selector?(selector:)).to eq(false)
        end
      end
    end
  end
end
