# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Oclc::Record, type: :model do
  let(:marc_record) { marc_reader.first }
  let(:marc_reader) { MARC::Reader.new(oclc_fixture_file_path.to_s, external_encoding: 'UTF-8') }
  let(:selector_config) { Rails.application.config.newly_cataloged.selectors.first }
  let(:selector) { Oclc::Selector.new(selector_config:) }
  let(:subject) { described_class.new(marc_record:) }

  context 'with a selector with a single call number, not a range' do
    let(:selector_config) { Rails.application.config.newly_cataloged.selectors.find { |selector| selector.keys.include?(:donatiello) } }
    let(:marc_record) { MARC::Record.new_from_hash('fields' => fields) }
    context 'with a matching call number' do
      let(:fields) do
        [
          { '050' => { 'indicator1' => ' ',
                       'indicator2' => ' ',
                       'subfields' => [{ 'a' => 'RA407.3' }] } }
        ]
      end
      it 'recognizes that it is relevant' do
        expect(subject.call_number_in_range_for_selector?(selector:)).to eq(true)
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
        expect(subject.call_number_in_range_for_selector?(selector:)).to eq(false)
      end
    end
  end
  context 'with a selector with a multi-part subject term' do
    let(:selector_config) { Rails.application.config.newly_cataloged.selectors.find { |selector| selector.keys.include?(:donatiello) } }
    let(:marc_record) { MARC::Record.new_from_hash('fields' => fields) }
    let(:fields) do
      [
        { '650' => { "ind1" => "",
                     "ind2" => "0",
                     'subfields' => [
                       { 'a' => 'Emigration and immigration',
                         'z' => 'Statistics' }
                     ] } }
      ]
    end
    it 'recognizes that it is relevant' do
      expect(subject.subject_relevant_to_selector?(selector:)).to eq(true)
    end
  end
  context 'fixture one' do
    let(:oclc_fixture_file_path) { Rails.root.join('spec', 'fixtures', 'oclc', 'metacoll.PUL.new.D20230718.T213016.MZallDLC.1.mrc') }

    context 'with relevant record 1' do
      let(:marc_record) do
        marc_reader.find { |record| record['001'].value.strip == "on1390709398" }
      end

      it 'can tell that the record is generally relevant' do
        expect(subject.juvenile?).to eq(false)
        expect(subject.audiobook?).to eq(false)
        expect(subject.published_in_us_uk_or_canada?).to eq(false)
        expect(subject.monograph?).to eq(true)
        expect(subject.within_last_two_years?).to eq(true)
        expect(subject.generally_relevant?).to eq(true)
        expect(subject.relevant_to_selector?(selector:)).to eq(true)
      end
    end

    context 'with relevant record 2' do
      let(:marc_record) do
        marc_reader.find { |record| record['001'].value.strip == "on1390704802" }
      end

      it 'can tell that the record is relevant' do
        expect(subject.juvenile?).to eq(false)
        expect(subject.audiobook?).to eq(false)
        expect(subject.published_in_us_uk_or_canada?).to eq(false)
        expect(subject.monograph?).to eq(true)
        expect(subject.within_last_two_years?).to eq(true)
        expect(subject.generally_relevant?).to eq(true)
        expect(subject.call_number_in_range_for_selector?(selector:)).to eq(true)
        expect(subject.relevant_to_selector?(selector:)).to eq(true)
      end
    end
  end

  describe 'call number parsing' do
    let(:oclc_fixture_file_path) { Rails.root.join('spec', 'fixtures', 'oclc', 'metacoll.PUL.new.D20230718.T213016.MZallDLC.1.mrc') }

    context 'with a call number with just a class' do
      before do
        allow(subject).to receive(:call_number).and_return('HD')
      end
      it 'has a zero lc_number' do
        expect(subject.call_number).to eq('HD')
        expect(subject.lc_class).to eq('HD')
        expect(subject.lc_number).to be 0.0
        expect(subject.call_number_in_range_for_selector?(selector:)).to be true
      end
    end

    context 'with a call number with decimals in it, in range' do
      context 'in range' do
        before do
          allow(subject).to receive(:call_number).and_return('G155.8 .C6 H83 2015')
        end

        it 'has that the call number is in range for the selector' do
          expect(subject.call_number).to eq('G155.8 .C6 H83 2015')
          expect(subject.lc_class).to eq('G')
          expect(subject.lc_number).to be 155.8
          expect(subject.call_number_in_range_for_selector?(selector:)).to be true
        end
      end
      context 'out of range' do
        before do
          allow(subject).to receive(:call_number).and_return('G155.9 .C6 H83 2015')
        end

        it 'has that the call number is out of range for selector' do
          expect(subject.call_number).to eq('G155.9 .C6 H83 2015')
          expect(subject.lc_class).to eq('G')
          expect(subject.lc_number).to be 155.9
          expect(subject.call_number_in_range_for_selector?(selector:)).to be false
        end
      end
    end
  end

  context 'fixture two' do
    let(:oclc_fixture_file_path) { Rails.root.join('spec', 'fixtures', 'oclc', 'metacoll.PUL.new.D20230706.T213019.MZallDLC.1.mrc') }

    it 'can be instantiated' do
      expect(described_class.new(marc_record:)).to be
    end

    it 'can tell if a record is generally relevant' do
      expect(subject.generally_relevant?).to be false
    end

    it 'can tell if a record is relevant to the selector' do
      expect(subject.relevant_to_selector?(selector:)).to be true
    end

    it 'can tell if a class is relevant to the selector' do
      expect(subject.lc_class).to eq('HD')
      expect(subject.class_relevant_to_selector?(selector:)).to be true
    end

    it 'can tell if a subject is relevant to the selector' do
      expect(subject.subject_relevant_to_selector?(selector:)).to be false
    end

    it 'can tell if a call number is in range for the selector' do
      expect(subject.call_number).to eq('HD7123 .A22 no. 3')
      expect(subject.call_number_in_range_for_selector?(selector:)).to be true
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
      expect(subject.subjects).to match_array(["Unemployment insurance -- Great Britain", "Health insurance -- Great Britain"])
    end

    it 'can tell if it was published within the last two years' do
      expect(subject.within_last_two_years?).to eq(false)
    end

    it 'can tell if it is a monograph file' do
      expect(subject.monograph?).to eq(true)
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

    context 'with a relevant work' do
      let(:marc_record) do
        marc_reader.find { |record| record['035']['a'] == "(OCoLC)1389531111" }
      end

      it 'can tell if a record is relevant to the selector' do
        expect(subject.call_number).to eq('U799 .O75')
        expect(subject.call_number_in_range_for_selector?(selector:)).to be false
        expect(subject.class_relevant_to_selector?(selector:)).to be false
        expect(subject.subject_relevant_to_selector?(selector:)).to be false
        expect(subject.relevant_to_selector?(selector:)).to be false
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
        expect(subject.non_romanized_title).to include('Оружейный сборник')
        expect(subject.f008_pub_place).to eq('ru')
        expect(subject.pub_place).to eq('Sankt-Peterburg')
        expect(subject.pub_name).to eq("Izdatel'stvo Gosudarstvennogo Ėrmitazha")
        expect(subject.pub_date).to eq('2021-')
        expect(subject.description).to eq('volumes : illustrations ; 26 cm')
        expect(subject.format).to eq('as')
        expect(subject.languages).to eq('rus | eng')
        expect(subject.subject_string).to eq("Gosudarstvennyĭ Ėrmitazh (Russia) -- Congresses |" \
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
        expect(subject.lc_class).to eq('KBR')
        expect(subject.class_relevant_to_selector?(selector:)).to be false
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
        expect(subject.author).to eq('Catholic Church Pope (1198-1216 : Innocent III)')
        expect(subject.title).to include("Die Register Innocenz' III")
        expect(subject.non_romanized_title).to eq('')
        expect(subject.f008_pub_place).to eq('au')
        expect(subject.pub_place).to eq('Graz ;')
        expect(subject.pub_name).to eq('Hermann Böhlaus Nachf.')
        expect(subject.pub_date).to eq('1964-1968')
        expect(subject.description).to eq('volumes <1, 2-3, 5-14>; 25 cm.')
        expect(subject.format).to eq('am')
        expect(subject.languages).to eq('ger | lat')
        expect(subject.subject_string).to eq("Innocent III, Pope, 1160 or 1161-1216 |" \
          " Church history -- 12th century -- Sources |" \
          " Church history -- 13th century -- Sources |" \
          " Papacy -- History -- To 1309 -- Sources |" \
          " Canon law -- Sources")
      end
    end
  end
end
