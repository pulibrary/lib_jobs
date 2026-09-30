# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Aspace2alma::ArchivalObjectRecord do
  def fixture_json(name)
    JSON.parse(file_fixture("aspace2alma/#{name}.json").read)
  end

  let(:resolved_ao_json) { fixture_json('resolved_archival_object') }
  let(:record) { described_class.new(resolved_ao_json) }
  let(:marc) { Nokogiri::XML(record.to_marc) }

  describe '.resolves' do
    it 'lists refs to resolve for mapping' do
      expect(described_class.resolves).to contain_exactly(
        'subjects', 'linked_agents', 'top_container', 'top_container::container_locations'
      )
    end

    it 'covers everything the mapping reads' do
      resolved_paths = described_class.resolves.map { |resolve| resolve.split('::').flat_map { |key| [key, '_resolved'] }[0..-2] }
      keep_only_resolves = lambda do |node, path|
        case node
        when Hash
          node.each_with_object({}) do |(key, value), kept|
            next if key == '_resolved' && resolved_paths.none? { |resolved_path| path.last(resolved_path.size) == resolved_path }

            kept[key] = keep_only_resolves.call(value, path + [key])
          end
        when Array then node.map { |value| keep_only_resolves.call(value, path) }
        else node
        end
      end
      fully_resolved = fixture_json('archival_object_extra_resolves')
      only_resolves = keep_only_resolves.call(fully_resolved, [])

      resolved_digital_objects = ->(json) { json['instances'].filter_map { |instance| instance.dig('digital_object', '_resolved') } }

      expect(resolved_digital_objects.call(fully_resolved)).not_to be_empty
      expect(resolved_digital_objects.call(only_resolves)).to be_empty
      expect(only_resolves['subjects'].first['_resolved']).to be_present
      expect(described_class.new(only_resolves).to_marc).to eq(described_class.new(fully_resolved).to_marc)
    end
  end

  describe '.collection_to_marc' do
    it 'wraps each mapped record in a MARCXML <collection>' do
      collection = Nokogiri::XML(described_class.collection_to_marc([resolved_ao_json, resolved_ao_json]))

      expect(collection.root.name).to eq('collection')
      expect(collection.xpath('//marc:record').size).to eq(2)
    end

    it "gives each record its collection's languages" do
      bolivar_letter = fixture_json('archival_object_multiple_extents')
      collection = Nokogiri::XML(described_class.collection_to_marc([bolivar_letter],
                                                                    collection_languages: { '/repositories/5/resources/3950' => ['spa'] }))

      expect(collection.at_xpath("//marc:controlfield[@tag='008']").content[35..37]).to eq('spa')
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
        ['mixed_materials', 'p', [23]],
        ['books', 'a', [23, 29, 30, 31, 33]],
        ['audio', 'i', [18, 19, 20, 23]],
        ['computer_disks', 'm', [23, 26]],
        ['graphic_materials', 'k', [18, 19, 20, 23, 33, 34]]
      ].each do |instance_type, type_of_record, fill_positions|
        context "for #{instance_type} (leader/06 '#{type_of_record}')" do
          let(:resolved_ao_json) do
            json = fixture_json('resolved_archival_object')
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
      expect(marc.xpath("//datafield[@tag='041']/subfield").map { |subfield| [subfield['code'], subfield.content] }).to eq([%w[a eng]])
    end

    context 'when the material is not in English' do
      let(:resolved_ao_json) { fixture_json('archival_object_lc_identifier') }

      it 'uses its language in 008 and 041' do
        expect(marc.at_xpath("//controlfield[@tag='008']").content[35..37]).to eq('spa')
        expect(marc.at_xpath("//datafield[@tag='041']/subfield[@code='a']").content).to eq('spa')
      end
    end

    context 'when the material is in several languages' do
      let(:resolved_ao_json) { fixture_json('archival_object_bare_viaf_number') }

      it 'puts the first in 008 and all of them in 041' do
        expect(marc.at_xpath("//controlfield[@tag='008']").content[35..37]).to eq('eng')
        expect(marc.xpath("//datafield[@tag='041']/subfield").map { |subfield| [subfield['code'], subfield.content] })
          .to eq([%w[a eng], %w[a ger]])
      end
    end

    context 'when the component records no language' do
      let(:resolved_ao_json) { fixture_json('archival_object_multiple_extents') }

      context 'and its collection does' do
        let(:record) { described_class.new(resolved_ao_json, collection_languages: ['spa']) }

        it "uses the collection's language" do
          expect(marc.at_xpath("//controlfield[@tag='008']").content[35..37]).to eq('spa')
          expect(marc.at_xpath("//datafield[@tag='041']/subfield[@code='a']").content).to eq('spa')
        end
      end

      context 'and neither does its collection' do
        it "uses 'und' in 008 and leaves out the 041" do
          expect(marc.at_xpath("//controlfield[@tag='008']").content[35..37]).to eq('und')
          expect(marc.xpath("//datafield[@tag='041']")).to be_empty
        end
      end
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

    context 'when an access restriction note and agent dates contain XML special characters' do
      let(:resolved_ao_json) do
        json = fixture_json('resolved_archival_object')
        json['notes'] << { 'type' => 'accessrestrict', 'subnotes' => [{ 'content' => 'Open to researchers & staff' }] }
        grover = json['linked_agents'].find { |agent| agent['_resolved']['names'][0]['primary_name'] == 'Grover' }
        grover['_resolved']['dates_of_existence'] = [{ 'structured_date_range' => { 'begin_date_expression' => '1611 & after' } }]
        json
      end

      it 'escapes them, and the record stays valid MARCXML' do
        strict = Nokogiri::XML(record.to_marc, &:strict)

        expect(strict.at_xpath("//datafield[@tag='506']/subfield[@code='a']").content).to eq('Open to researchers & staff')
        expect(strict.at_xpath("//datafield[@tag='600'][subfield[@code='a']='Grover, James,']/subfield[@code='d']").content)
          .to eq('1611 & after')
      end
    end

    context 'when the title has EAD markup' do
      let(:resolved_ao_json) do
        fixture_json('resolved_archival_object')
          .merge('title' => 'Notes on <emph render="italic">Leaves of Grass</emph> & other works')
      end

      it 'removes the tags and escapes the rest' do
        expect(Nokogiri::XML(record.to_marc, &:strict).at_xpath("//datafield[@tag='245']/subfield[@code='a']").content)
          .to eq('Notes on Leaves of Grass & other works')
      end
    end

    context 'when the ao has no title' do
      let(:resolved_ao_json) do
        fixture_json('resolved_archival_object').merge('title' => nil)
      end
      let(:tag245) { marc.at_xpath("//datafield[@tag='245']") }

      it "uses the first date's expression in $a, without $f" do
        expect(tag245.xpath('subfield').map { |subfield| [subfield['code'], subfield.content] }).to eq([['a', '1674 August 24']])
      end

      context 'and that date has no expression' do
        let(:resolved_ao_json) do
          fixture_json('resolved_archival_object')
            .merge('title' => '', 'dates' => [{ 'date_type' => 'inclusive', 'label' => 'creation', 'begin' => '1674', 'end' => '1677' }])
        end

        it 'uses its begin and end dates' do
          expect(tag245.at_xpath("subfield[@code='a']").content).to eq('1674 - 1677')
        end
      end
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

    describe 'agent dates in $d' do
      let(:resolved_ao_json) do
        json = fixture_json('resolved_archival_object')
        grover = json['linked_agents'].find { |agent| agent['_resolved']['names'][0]['primary_name'] == 'Grover' }
        grover['_resolved']['names'][0]['use_dates'] = use_dates
        grover['_resolved']['dates_of_existence'] = dates_of_existence
        json
      end
      let(:use_dates) { [] }
      let(:dates_of_existence) { [] }
      let(:subfield_d) { marc.at_xpath("//datafield[@tag='600'][subfield[@code='a']='Grover, James,']/subfield[@code='d']") }

      context 'when the expression holds the whole range and only the end is standardized' do
        let(:dates_of_existence) do
          [{ 'structured_date_range' => { 'begin_date_expression' => '1611-1685', 'end_date_standardized' => '1685' } }]
        end

        it 'uses the expression only' do
          expect(subfield_d.content).to eq('1611-1685')
        end
      end

      context 'when the expressions carry a qualifier' do
        let(:dates_of_existence) do
          [{ 'structured_date_range' => { 'begin_date_expression' => 'approximately 1611', 'end_date_expression' => '1685',
                                          'begin_date_standardized' => '1611', 'end_date_standardized' => '1685' } }]
        end

        it 'keeps the expressions' do
          expect(subfield_d.content).to eq('approximately 1611-1685')
        end
      end

      context 'when there are only standardized full dates' do
        let(:dates_of_existence) do
          [{ 'structured_date_range' => { 'begin_date_standardized' => '1611-03-02', 'end_date_standardized' => '1685-07-14' } }]
        end

        it 'uses their years' do
          expect(subfield_d.content).to eq('1611-1685')
        end
      end

      context 'when a use date range has only standardized dates' do
        let(:use_dates) do
          [{ 'structured_date_range' => { 'begin_date_standardized' => '1650', 'end_date_standardized' => '1680' } }]
        end
        let(:dates_of_existence) do
          [{ 'structured_date_range' => { 'begin_date_standardized' => '1611', 'end_date_standardized' => '1685' } }]
        end

        it 'uses the use date, not the dates of existence' do
          expect(subfield_d.content).to eq('1650-1680')
        end
      end

      context 'when a use date has no dates' do
        let(:use_dates) { [{ 'structured_date_range' => {} }] }
        let(:dates_of_existence) do
          [{ 'structured_date_range' => { 'begin_date_standardized' => '1611', 'end_date_standardized' => '1685' } }]
        end

        it 'falls back to the dates of existence' do
          expect(subfield_d.content).to eq('1611-1685')
        end
      end

      context 'when the date is a single date' do
        let(:dates_of_existence) { [{ 'structured_date_single' => { 'date_standardized' => '1611-03-02' } }] }

        it 'uses its year' do
          expect(subfield_d.content).to eq('1611')
        end
      end

      context 'when there are no dates' do
        it 'has no $d' do
          expect(subfield_d).to be_nil
        end
      end
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

    it 'constructs a 300 from the extent' do
      tag300s = marc.xpath("//datafield[@tag='300']")

      expect(tag300s.size).to eq(1)
      expect(tag300s.first.xpath('subfield').map { |subfield| [subfield['code'], subfield.content] }).to eq([%w[a 1], %w[f folder]])
    end

    context 'when there are several extents' do
      let(:resolved_ao_json) { fixture_json('archival_object_multiple_extents') }

      it 'constructs one 300 per extent' do
        tag300s = marc.xpath("//datafield[@tag='300']").map do |field|
          field.xpath('subfield').map { |subfield| [subfield['code'], subfield.content] }
        end

        expect(tag300s).to eq([[%w[a 0.05], ['f', 'linear feet']], [%w[a 1], %w[f item]]])
      end
    end

    context 'when an extent has physical details and dimensions' do
      let(:resolved_ao_json) { fixture_json('archival_object_extent_details') }

      it 'puts them in $b and $c' do
        expect(marc.at_xpath("//datafield[@tag='300']").xpath('subfield').map { |subfield| [subfield['code'], subfield.content] })
          .to eq([%w[a 1], %w[f item], ['b', '1 page'], ['c', '21 x 16 cm']])
      end
    end

    context 'when an extent has a container summary' do
      let(:resolved_ao_json) { fixture_json('archival_object_container_summary') }

      it 'adds it to $f in parentheses' do
        expect(marc.at_xpath("//datafield[@tag='300']/subfield[@code='f']").content).to eq('folder (1 volume)')
      end
    end

    context 'when there are no extents' do
      let(:resolved_ao_json) do
        fixture_json('resolved_archival_object').merge('extents' => [])
      end

      it 'has no 300' do
        expect(marc.xpath("//datafield[@tag='300']")).to be_empty
      end
    end

    context 'when a heading is a single term with -- subdivisions' do
      let(:resolved_ao_json) do
        json = fixture_json('resolved_archival_object')
        json['subjects'][0]['_resolved']['terms'] = [{ 'term' => 'Delaware Indians -- History -- 17th century', 'term_type' => 'topical' }]
        json
      end

      it 'splits it into trimmed $a, $x and $y' do
        tag650 = marc.at_xpath("//datafield[@tag='650'][subfield[@code='a']='Delaware Indians']")

        expect(tag650.xpath('subfield').map { |subfield| [subfield['code'], subfield.content] }).to eq(
          [%w[a Delaware\ Indians], %w[x History], %w[y 17th\ century]]
        )
      end
    end

    context 'when a heading has separate terms' do
      let(:resolved_ao_json) do
        json = fixture_json('resolved_archival_object')
        json['subjects'][0]['_resolved']['terms'] = [
          { 'term' => 'Delaware Indians ', 'term_type' => 'topical' },
          { 'term' => 'History', 'term_type' => 'topical' }
        ]
        json
      end

      it 'trims $a too' do
        expect(marc.at_xpath("//datafield[@tag='650'][subfield[@code='a']='Delaware Indians']/subfield[@code='x']").content)
          .to eq('History')
      end
    end

    it 'maps scope and acquisition notes to 520 and 541' do
      expect(marc.at_xpath("//datafield[@tag='520']/subfield[@code='a']").content)
        .to start_with('Consists of a deed transferring land from Matappeas, Tawapung (Taptawappamund)')
      expect(marc.at_xpath("//datafield[@tag='541']/subfield[@code='a']").content)
        .to eq('Gift of Harry Irvin Caesar, Class of 1913, in 1956 (AM 15674).')
    end

    it 'removes EAD markup and stray spaces from notes' do
      raw = resolved_ao_json['notes'].select { |note| note['type'] == 'scopecontent' }[1]['subnotes'][0]['content']

      expect(raw).to eq('Visit <extref xmlns:xlin="http://www.w3.org/1999/xlink" ' \
                        'xlin:href="https://dpul.princeton.edu/lenape/catalog/70795j14c" xlin:type="simple">Digital PUL</extref> ' \
                        'for more information about the Sand Hill Indians.  ')
      expect(marc.xpath("//datafield[@tag='520']/subfield[@code='a']")[1].content)
        .to eq('Visit Digital PUL for more information about the Sand Hill Indians.')
    end

    context 'when a note has line breaks' do
      let(:resolved_ao_json) { fixture_json('archival_object_extent_details') }
      let(:raw) { resolved_ao_json['notes'].find { |note| note['type'] == 'scopecontent' }['subnotes'][0]['content'] }
      let(:normalized) { marc.at_xpath("//datafield[@tag='520']/subfield[@code='a']").content }

      it 'turns them into single spaces' do
        expect(raw).to include("at the court's request.\n\nIncludes only", "Benjamin Guerard, Esq. \nDocket title")
        expect(normalized).to include("at the court's request. Includes only", 'Benjamin Guerard, Esq. Docket title')
        expect(normalized).not_to match(/\n|\s{2}/)
      end
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
        json = fixture_json('resolved_archival_object')
        json['linked_agents'][0]['_resolved']['names'][0].merge!('source' => 'local', 'authority_id' => nil)
        json
      end

      it 'puts $5 in 7xx only' do
        expect(marc.at_xpath("//datafield[@tag='110']/subfield[@code='5']")).to be_nil
        expect(marc.at_xpath("//datafield[@tag='710']/subfield[@code='5']").content).to eq('NjP')
      end
    end

    context 'when VIAF URIs are stored as https or on an lcnaf name' do
      let(:resolved_ao_json) { fixture_json('archival_object_extent_details') }

      it 'rewrites an https VIAF URI to the canonical http form in $1' do
        expect(marc.at_xpath("//datafield[@tag='100']/subfield[@code='1']").content).to eq('http://viaf.org/viaf/72204820')
        expect(marc.at_xpath("//datafield[@tag='700']/subfield[@code='1']").content).to eq('http://viaf.org/viaf/72204820')
      end

      it 'puts a VIAF URI on an lcnaf name in $1 too' do
        tag600 = marc.at_xpath("//datafield[@tag='600'][subfield[@code='a']='Guerard, Benjamin.']")

        expect(tag600['ind2']).to eq('0')
        expect(tag600.at_xpath("subfield[@code='1']").content).to eq('http://viaf.org/viaf/6496900')
        expect(tag600.xpath("subfield[@code='0' or @code='2']")).to be_empty
      end
    end

    describe 'agent identifiers' do
      let(:resolved_ao_json) do
        json = fixture_json('resolved_archival_object')
        json['linked_agents'][0]['_resolved']['names'][0].merge!('authority_id' => identifier, 'source' => source)
        json
      end
      let(:source) { 'viaf' }
      let(:tag110) { marc.at_xpath("//datafield[@tag='110']") }

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

          it 'drops it' do
            expect(tag110.xpath("subfield[@code='0' or @code='1']")).to be_empty
          end
        end
      end

      ['(DLC)n  79041954', 'n79041954'].each do |not_a_uri|
        context "when it is #{not_a_uri} on an lcnaf name" do
          let(:identifier) { not_a_uri }
          let(:source) { 'lcnaf' }

          it 'drops it' do
            expect(tag110.xpath("subfield[@code='0' or @code='1']")).to be_empty
          end
        end
      end
    end

    context 'when an identifier is an LC URI' do
      let(:resolved_ao_json) { fixture_json('archival_object_lc_identifier') }

      it 'puts it in $0 unchanged' do
        tag610 = marc.at_xpath("//datafield[@tag='610'][subfield[@code='a']='Jesuits.']")

        expect(tag610.at_xpath("subfield[@code='0']").content).to eq('http://id.loc.gov/authorities/names/n79046634')
        expect(tag610.at_xpath("subfield[@code='1']")).to be_nil
      end
    end

    context 'when a VIAF URI has a language segment in its path' do
      let(:resolved_ao_json) { fixture_json('archival_object_viaf_language_path') }

      it 'puts the canonical VIAF URI in $1' do
        expect(marc.at_xpath("//datafield[@tag='610']/subfield[@code='1']").content).to eq('http://viaf.org/viaf/146604278')
      end
    end

    context 'when a viaf-sourced name has a bare number' do
      let(:resolved_ao_json) { fixture_json('archival_object_bare_viaf_number') }

      it 'treats it as a VIAF number' do
        tag610 = marc.at_xpath("//datafield[@tag='610']")

        expect(tag610.at_xpath("subfield[@code='1']").content).to eq('http://viaf.org/viaf/153631640')
        expect(tag610.at_xpath("subfield[@code='0']")).to be_nil
      end
    end

    context 'when a viaf-sourced name has an identifier that is not VIAF' do
      let(:resolved_ao_json) { fixture_json('archival_object_lccn_labeled_viaf') }

      it 'drops it' do
        expect(marc.xpath("//datafield/subfield[@code='0' or @code='1']")).to be_empty
      end
    end

    context 'when a name ends in a period and has dates' do
      let(:resolved_ao_json) { fixture_json('archival_object_several_creation_dates') }

      it 'still puts a comma before $d' do
        expect(marc.at_xpath("//datafield[@tag='100']/subfield[@code='a']").content).to eq('Kimball, John R.,')
      end
    end

    context 'when an agent is lcsh-sourced' do
      let(:resolved_ao_json) { fixture_json('archival_object_extent_details') }

      it 'codes it like an LC heading, without $2' do
        tag610 = marc.at_xpath("//datafield[@tag='610'][subfield[@code='a']='Massachusetts.']")

        expect(tag610['ind2']).to eq('0')
        expect(tag610.at_xpath("subfield[@code='2']")).to be_nil
      end
    end

    context 'when the creation date is a range' do
      let(:resolved_ao_json) { fixture_json('archival_object_inclusive_dates') }

      it 'they are marked inclusive in 008/046/245$f' do
        expect(marc.at_xpath("//controlfield[@tag='008']").content[6..14]).to eq('i18371885')
        expect(marc.xpath("//datafield[@tag='046']/subfield").map(&:content)).to eq(%w[i 1837 1885])
        expect(marc.at_xpath("//datafield[@tag='245']/subfield[@code='f']").content).to eq('1837-1885')
      end
    end

    context 'when there are several creation dates' do
      let(:resolved_ao_json) { fixture_json('archival_object_several_creation_dates') }

      it 'takes earliest and latest and makes them a range' do
        expect(marc.at_xpath("//controlfield[@tag='008']").content[6..14]).to eq('i18371899')
        expect(marc.xpath("//datafield[@tag='046']/subfield").map(&:content)).to eq(%w[i 1837 1899])
        expect(marc.at_xpath("//datafield[@tag='245']/subfield[@code='f']").content).to eq('1837-1899')
      end
    end

    context 'when the ao is undated' do
      let(:resolved_ao_json) { fixture_json('archival_object_undated') }

      it 'uses unknown in 008' do
        expect(marc.at_xpath("//controlfield[@tag='008']").content[6..14]).to eq('nuuuuuuuu')
      end

      it "does not create a 046, and puts 'undated' in 245$f" do
        expect(marc.xpath("//datafield[@tag='046']")).to be_empty
        expect(marc.xpath("//datafield[@tag='245']/subfield").map { |subfield| [subfield['code'], subfield.content] })
          .to eq([['a', 'Princeton Alumni Weekly, Comics'], %w[f undated]])
      end
    end

    context 'when some dates have years only in their expression' do
      let(:resolved_ao_json) { fixture_json('archival_object_date_expression_only') }

      it 'uses only the dates with a begin date' do
        expect(marc.at_xpath("//controlfield[@tag='008']").content[6..14]).to eq('i19061906')
        expect(marc.at_xpath("//datafield[@tag='245']/subfield[@code='f']").content).to eq('1906')
      end
    end

    context 'when there is no accessrestrict' do
      let(:resolved_ao_json) do
        json = fixture_json('resolved_archival_object')
        json['notes'] = json['notes'].reject { |note| note['type'] == 'accessrestrict' }
        json
      end

      it 'uses the default accessrestrict' do
        expect(marc.at_xpath("//datafield[@tag='506']/subfield[@code='a']").content).to eq(described_class::DEFAULT_RESTRICTION)
      end
    end

    context 'when the digital object instance comes before the physical one' do
      let(:resolved_ao_json) do
        json = fixture_json('resolved_archival_object')
        json['instances'][0]['instance_type'] = 'audio'
        json['instances'].reverse!
        json
      end

      it 'uses the physical instance for leader/06' do
        expect(marc.at_xpath('//leader').content[6]).to eq('i')
      end

      it 'uses the physical instance for the 982' do
        expect(marc.at_xpath("//datafield[@tag='982']/subfield[@code='c']").content).to eq('scahsvm')
      end
    end

    context 'when the ao has no containers' do
      let(:resolved_ao_json) do
        fixture_json('resolved_archival_object').merge('instances' => [])
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
        fixture_json('resolved_archival_object').merge('dates' => [])
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
