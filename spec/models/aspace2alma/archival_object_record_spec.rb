# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Aspace2alma::ArchivalObjectRecord do
  let(:resolved_ao_json) { JSON.parse(file_fixture('aspace2alma/resolved_archival_object.json').read) }
  let(:record) { described_class.new(resolved_ao_json) }
  let(:marc) { Nokogiri::XML(record.to_marc) }

  describe '.resolves' do
    it 'lists refs to resolve for mapping' do
      expect(described_class.resolves).to eq(
        %w[subjects linked_agents top_container top_container::container_locations]
      )
    end
  end

  describe '.collection_to_marc' do
    it 'wraps each mapped record in a MARCXML <collection>' do
      collection = Nokogiri::XML(described_class.collection_to_marc([resolved_ao_json, resolved_ao_json]))

      expect(collection.root.name).to eq('collection')
      expect(collection.xpath('//marc:record').size).to eq(2)
    end
  end

  describe '#to_marc' do
    it 'produces a single MARC record' do
      expect(marc.root.name).to eq('record')
    end

    it 'maps ref_id to 001/035/099' do
      expect(marc.at_xpath("//controlfield[@tag='001']").content).to eq('C0140_c00123')
      expect(marc.at_xpath("//datafield[@tag='035']/subfield[@code='a']").content).to eq('(PULFA)C0140_c00123')
      expect(marc.at_xpath("//datafield[@tag='099']/subfield[@code='a']").content).to eq('C0140_c00123')
    end

    it 'puts the date in 008' do
      tag008 = marc.at_xpath("//controlfield[@tag='008']").content

      expect(tag008[6]).to eq('e')
      expect(tag008[7..10]).to eq('1925')
      expect(tag008[11..14]).to eq('1926')
    end

    describe 'controlfield 008/18-34' do
      # some of these need "|" not " "
      [
        ['mixed_materials', 't', [23, 29, 30, 31, 33]],
        ['books', 'a', [23, 29, 30, 31, 33]],
        ['audio', 'i', [18, 19, 20, 23]],
        ['computer_disks', 'm', [23, 26]],
        ['graphic_materials', 'k', [18, 19, 20, 23, 33, 34]]
      ].each do |instance_type, type_of_record, fill_positions|
        context "for #{instance_type} (leader/06 '#{type_of_record}')" do
          let(:resolved_ao_json) do
            json = JSON.parse(file_fixture('aspace2alma/resolved_archival_object.json').read)
            json['instances'][0]['instance_type'] = instance_type
            json
          end

          it "uses '|' where required by MARC and blanks otherwise" do
            tag008 = marc.at_xpath("//controlfield[@tag='008']").content

            expect(marc.at_xpath('//leader').content[6]).to eq(type_of_record)
            expect(tag008.length).to eq(40)
            (18..34).each do |position|
              expect(tag008[position]).to eq(fill_positions.include?(position) ? '|' : ' '), "008/#{position}"
            end
          end
        end
      end
    end

    it 'constructs 041 language code from 008' do
      expect(marc.at_xpath("//datafield[@tag='041']/subfield[@code='c']").content).to eq('eng')
    end

    it 'constructs a 046 from 008' do
      tag046 = marc.at_xpath("//datafield[@tag='046']")

      expect(tag046.at_xpath("subfield[@code='c']").content).to eq('1925')
      expect(tag046.at_xpath("subfield[@code='e']").content).to eq('1926')
    end

    it 'constructs a 245' do
      tag245 = marc.at_xpath("//datafield[@tag='245']")

      expect(tag245.at_xpath("subfield[@code='a']").content).to eq('Letter from Jane Doe to John Smith')
      expect(tag245.at_xpath("subfield[@code='f']").content).to eq('1925-1926')
    end

    it 'constructs a 1xx' do
      tag100 = marc.at_xpath("//datafield[@tag='100']")

      expect(tag100['ind1']).to eq('1') # agent_person => name_type 1
      expect(tag100['ind2']).to eq('0') # source 'lcnaf' => source_code 0
      expect(tag100.at_xpath("subfield[@code='a']").content).to eq('Doe, Jane,') # trailing ',' because dates follow
      expect(tag100.at_xpath("subfield[@code='d']").content).to eq('1899-1990')
      expect(tag100.at_xpath("subfield[@code='0']").content).to eq('http://id.loc.gov/authorities/names/n12345678')
    end

    it 'constructs a 7xx' do
      expect(marc.at_xpath("//datafield[@tag='700']/subfield[@code='a']").content).to eq('Doe, Jane,')
    end

    it 'constructs a 6xx' do
      tag610 = marc.at_xpath("//datafield[@tag='610']")

      expect(tag610['ind2']).to eq('7') # source 'local' => source_code 7
      expect(tag610.at_xpath("subfield[@code='a']").content).to eq('Spring Letters Press.')
      expect(tag610.at_xpath("subfield[@code='2']").content).to eq('local')
      expect(tag610.at_xpath("subfield[@code='5']").content).to eq('NjP')
    end

    it 'constructs lc headings' do
      tag650 = marc.at_xpath("//datafield[@tag='650']")

      expect(tag650['ind2']).to eq('0')
      expect(tag650.at_xpath("subfield[@code='a']").content).to eq('Poetry')
      expect(tag650.at_xpath("subfield[@code='y']").content).to eq('20th century')
      expect(tag650.at_xpath("subfield[@code='2']")).to be_nil
    end

    it 'constructs non-lc headings' do
      tag655 = marc.at_xpath("//datafield[@tag='655']")

      expect(tag655['ind2']).to eq('7')
      expect(tag655.at_xpath("subfield[@code='a']").content).to eq('Correspondence')
      expect(tag655.at_xpath("subfield[@code='2']").content).to eq('aat')
    end

    it 'constructs notes with normalized text' do
      expect(marc.at_xpath("//datafield[@tag='520']/subfield[@code='a']").content)
        .to eq('Correspondence concerning the publication of Spring Letters.')
      expect(marc.at_xpath("//datafield[@tag='545']/subfield[@code='a']").content)
        .to eq('Jane Doe (1899-1990) was a poet and editor.')
    end

    it 'constructs a 506' do
      expect(marc.at_xpath("//datafield[@tag='506']/subfield[@code='a']").content).to eq('Restricted until 2050.')
    end

    it 'constructs an 856' do
      tag856 = marc.at_xpath("//datafield[@tag='856']")

      expect(tag856.at_xpath("subfield[@code='u']").content)
        .to eq('https://findingaids.princeton.edu/catalog/C0140_c00123')
    end

    it 'constructs a 982 from the top_container' do
      expect(marc.at_xpath("//datafield[@tag='982']/subfield[@code='c']").content).to eq('scarcpph')
    end

    context 'when there is no accessrestrict' do
      let(:resolved_ao_json) do
        json = JSON.parse(file_fixture('aspace2alma/resolved_archival_object.json').read)
        json['notes'] = json['notes'].reject { |note| note['type'] == 'accessrestrict' }
        json
      end

      it 'uses the default accessrestrict' do
        expect(marc.at_xpath("//datafield[@tag='506']/subfield[@code='a']").content).to eq(described_class::DEFAULT_RESTRICTION)
      end
    end

    context 'when the ao has no containers' do
      let(:resolved_ao_json) do
        JSON.parse(file_fixture('aspace2alma/resolved_archival_object.json').read).merge('instances' => [])
      end

      it 'does not construct a 982' do
        expect(marc.xpath("//datafield[@tag='982']")).to be_empty
      end

      it 'puts t in leader/06' do
        expect(marc.at_xpath('//leader').content).to start_with('00000nt')
      end
    end

    context 'when an ao has no dates' do
      let(:resolved_ao_json) do
        JSON.parse(file_fixture('aspace2alma/resolved_archival_object.json').read).merge('dates' => [])
      end

      it 'puts | in 008/06' do
        tag008 = marc.at_xpath("//controlfield[@tag='008']").content

        expect(tag008.length).to eq(40)
        expect(tag008[6]).to eq('|')
        expect(tag008[7..14]).to eq(' ' * 8)
        expect(tag008[35..37]).to eq('eng')
      end

      it 'drops 046 and 245$f' do
        expect(marc.xpath("//datafield[@tag='046']")).to be_empty
        expect(marc.at_xpath("//datafield[@tag='245']/subfield[@code='f']")).to be_nil
      end
    end
  end
end
