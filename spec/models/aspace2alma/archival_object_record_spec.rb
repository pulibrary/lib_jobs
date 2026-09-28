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
      expect(marc.at_xpath("//controlfield[@tag='001']").content).to eq('C0140_c03353')
      expect(marc.at_xpath("//datafield[@tag='035']/subfield[@code='a']").content).to eq('(PULFA)C0140_c03353')
      expect(marc.at_xpath("//datafield[@tag='099']/subfield[@code='a']").content).to eq('C0140_c03353')
    end

    it 'puts a single creation date in 008' do
      tag008 = marc.at_xpath("//controlfield[@tag='008']").content

      expect(tag008[6]).to eq('s')
      expect(tag008[7..10]).to eq('1674')
      expect(tag008[11..14]).to eq('    ')
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

    it 'constructs a 046 from the dates' do
      tag046 = marc.at_xpath("//datafield[@tag='046']")

      expect(tag046.at_xpath("subfield[@code='a']").content).to eq('s')
      expect(tag046.at_xpath("subfield[@code='c']").content).to eq('1674')
      expect(tag046.at_xpath("subfield[@code='e']")).to be_nil
    end

    it 'constructs a 245' do
      tag245 = marc.at_xpath("//datafield[@tag='245']")

      expect(tag245.at_xpath("subfield[@code='a']").content)
        .to start_with('Deed from Matappeas, Tawapung, and Seapoekne to John Bowne')
      expect(tag245.at_xpath("subfield[@code='f']").content).to eq('1674')
    end

    it 'constructs a 1xx' do
      tag110 = marc.at_xpath("//datafield[@tag='110']")

      expect(tag110['ind1']).to eq('2') # agent_corporate_entity, direct order
      expect(tag110['ind2']).to eq(' ') # undefined in 1xx
      expect(tag110.at_xpath("subfield[@code='a']").content).to eq('Province of New Jersey.')
      expect(tag110.at_xpath("subfield[@code='4']").content).to eq('cre')
    end

    it 'puts a VIAF URI in $1 in the 1xx' do
      tag110 = marc.at_xpath("//datafield[@tag='110']")

      expect(tag110.at_xpath("subfield[@code='1']").content).to eq('http://viaf.org/viaf/128547839')
      expect(tag110.xpath("subfield[@code='0' or @code='2' or @code='5']")).to be_empty
    end

    it 'constructs a 7xx' do
      expect(marc.at_xpath("//datafield[@tag='710']/subfield[@code='a']").content).to eq('Province of New Jersey.')
    end

    it 'constructs a 6xx' do
      tag610 = marc.at_xpath("//datafield[@tag='610']")

      expect(tag610['ind2']).to eq('7') # source 'local' => source_code 7
      expect(tag610.at_xpath("subfield[@code='a']").content).to eq('Sand Hill Indians.')
      expect(tag610.at_xpath("subfield[@code='2']").content).to eq('local')
      expect(tag610.at_xpath("subfield[@code='5']").content).to eq('NjP')
    end

    it 'masks viaf' do
      tag600 = marc.at_xpath("//datafield[@tag='600'][subfield[@code='a']='Hartshorne, Richard,']")

      expect(tag600['ind2']).to eq('0')
      expect(tag600.at_xpath("subfield[@code='1']").content).to eq('http://viaf.org/viaf/9730823')
      expect(tag600.xpath("subfield[@code='0' or @code='2']")).to be_empty
    end

    it 'puts name qualifier in $g' do
      tag600 = marc.at_xpath("//datafield[@tag='600'][subfield[@code='a']='Hartshorne, Richard,']")

      expect(tag600.at_xpath("subfield[@code='g']").content).to eq('of New Jersey')
    end

    it "uses dates of existence for agent dates" do
      tag600 = marc.at_xpath("//datafield[@tag='600'][subfield[@code='a']='Grover, James,']")

      expect(tag600.at_xpath("subfield[@code='d']").content).to eq('1611-1685')
    end

    it 'constructs lc headings' do
      tag650 = marc.at_xpath("//datafield[@tag='650'][subfield[@code='a']='Land tenure']")

      expect(tag650['ind2']).to eq('0')
      expect(tag650.xpath('subfield').map { |subfield| [subfield['code'], subfield.content.strip] }).to eq(
        [%w[a Land\ tenure], %w[z New\ Jersey], %w[z Monmouth\ County], %w[x History], %w[y 17th\ century], %w[v Sources]]
      )
    end

    it 'constructs non-lc headings' do
      tag650 = marc.at_xpath("//datafield[@tag='650'][subfield[@code='a']='Indigenous Studies']")

      expect(tag650['ind2']).to eq('7')
      expect(tag650.at_xpath("subfield[@code='2']").content).to eq('local')
      expect(tag650.at_xpath("subfield[@code='5']").content).to eq('NjP')
    end

    it 'constructs notes with normalized text' do
      expect(marc.at_xpath("//datafield[@tag='520']/subfield[@code='a']").content)
        .to start_with('Consists of a deed transferring land from Matappeas, Tawapung (Taptawappamund)')
      expect(marc.at_xpath("//datafield[@tag='541']/subfield[@code='a']").content)
        .to eq('Gift of Harry Irvin Caesar, Class of 1913, in 1956 (AM 15674).')
    end

    it 'constructs a 506' do
      expect(marc.at_xpath("//datafield[@tag='506']/subfield[@code='a']").content).to eq(described_class::DEFAULT_RESTRICTION)
    end

    it 'constructs an 856' do
      tag856 = marc.at_xpath("//datafield[@tag='856']")

      expect(tag856.at_xpath("subfield[@code='u']").content)
        .to eq('https://findingaids.princeton.edu/catalog/C0140_c03353')
    end

    it 'constructs a 982 from the top_container' do
      expect(marc.at_xpath("//datafield[@tag='982']/subfield[@code='c']").content).to eq('scahsvm')
    end

    context 'when the creator has source=local' do
      let(:resolved_ao_json) do
        json = JSON.parse(file_fixture('aspace2alma/resolved_archival_object.json').read)
        json['linked_agents'][0]['_resolved']['names'][0].merge!('source' => 'local', 'authority_id' => nil)
        json
      end

      it 'puts $5 in 7xx only' do
        expect(marc.at_xpath("//datafield[@tag='110']/subfield[@code='5']")).to be_nil
        expect(marc.at_xpath("//datafield[@tag='710']/subfield[@code='5']").content).to eq('NjP')
      end
    end

    describe 'agent identifiers' do
      let(:resolved_ao_json) do
        json = JSON.parse(file_fixture('aspace2alma/resolved_archival_object.json').read)
        json['linked_agents'][0]['_resolved']['names'][0]['authority_id'] = identifier
        json
      end
      let(:tag110) { marc.at_xpath("//datafield[@tag='110']") }

      before { allow(Rails.logger).to receive(:warn) }

      [
        'https://viaf.org/viaf/128547839',
        'http://www.viaf.org/viaf/128547839/',
        'viaf 128547839',
        'VIAF:128547839',
        '(viaf)128547839'
      ].each do |viaf_form|
        context "when it is #{viaf_form}" do
          let(:identifier) { viaf_form }

          it 'puts the canonical VIAF URI in $1' do
            expect(tag110.at_xpath("subfield[@code='1']").content).to eq('http://viaf.org/viaf/128547839')
            expect(tag110.at_xpath("subfield[@code='0']")).to be_nil
          end
        end
      end

      [
        'https://example.com/viaf.org/128547839',
        'https://viaf.org/search?q=Province',
        'viaf number unknown'
      ].each do |malformed|
        context "when it is the malformed VIAF identifier #{malformed}" do
          let(:identifier) { malformed }

          it 'drops it and logs a warning' do
            expect(tag110.xpath("subfield[@code='0' or @code='1']")).to be_empty
            expect(Rails.logger).to have_received(:warn)
              .with(/dropped malformed VIAF identifier '#{Regexp.escape(malformed)}' for Province of New Jersey on C0140_c03353/)
              .at_least(:once)
          end
        end
      end

      [
        'http://id.loc.gov/authorities/names/n79041954',
        '(DLC)n  79041954'
      ].each do |other|
        context "when it is #{other}" do
          let(:identifier) { other }

          it 'puts it in $0 unchanged' do
            expect(tag110.at_xpath("subfield[@code='0']").content).to eq(other)
            expect(tag110.at_xpath("subfield[@code='1']")).to be_nil
          end
        end
      end
    end

    context 'when the creation dateis a range' do
      let(:resolved_ao_json) do
        json = JSON.parse(file_fixture('aspace2alma/resolved_archival_object.json').read)
        json['dates'] = [{ 'date_type' => 'inclusive', 'label' => 'creation', 'begin' => '1674-08-24', 'end' => '1677-03-02' }]
        json
      end

      it 'they are marked inclusive in 008/046/245$f' do
        expect(marc.at_xpath("//controlfield[@tag='008']").content[6..14]).to eq('i16741677')
        expect(marc.xpath("//datafield[@tag='046']/subfield").map(&:content)).to eq(%w[i 1674 1677])
        expect(marc.at_xpath("//datafield[@tag='245']/subfield[@code='f']").content).to eq('1674-1677')
      end
    end

    context 'when there are multiple single creation dates' do
      let(:resolved_ao_json) do
        json = JSON.parse(file_fixture('aspace2alma/resolved_archival_object.json').read)
        json['dates'][1]['label'] = 'creation'
        json
      end

      it 'takes earliest and latest and makes them a range' do
        expect(marc.at_xpath("//controlfield[@tag='008']").content[6..14]).to eq('i16741677')
      end
    end

    context 'there is no begin date' do
      let(:resolved_ao_json) do
        JSON.parse(file_fixture('aspace2alma/resolved_archival_object.json').read)
            .merge('dates' => [{ 'date_type' => 'single', 'label' => 'creation', 'expression' => 'undated' }])
      end

      it "uses unknown" do
        expect(marc.at_xpath("//controlfield[@tag='008']").content[6..14]).to eq('nuuuuuuuu')
      end

      it 'does not create 046 and 245$f' do
        expect(marc.xpath("//datafield[@tag='046']")).to be_empty
        expect(marc.at_xpath("//datafield[@tag='245']/subfield[@code='f']")).to be_nil
      end
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

      it 'does not create 046 and 245$f' do
        expect(marc.xpath("//datafield[@tag='046']")).to be_empty
        expect(marc.at_xpath("//datafield[@tag='245']/subfield[@code='f']")).to be_nil
      end
    end
  end
end
