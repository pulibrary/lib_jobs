# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Aspace2alma::SendMarcxmlToAlmaJob do
  subject(:job) { described_class.new }

  let(:client) { instance_double(ArchivesSpace::Client) }
  let(:fixture_xml) { file_fixture("aspace2alma/#{fixture}.xml").read }
  let(:doc) do
    job.run
    Nokogiri::XML(File.read('MARC_out.xml'))
  end

  def fields(tag)
    doc.xpath("//marc:datafield[@tag='#{tag}']")
  end

  def field(tag, heading)
    doc.at_xpath("//marc:datafield[@tag='#{tag}'][marc:subfield[@code='a'][starts-with(., \"#{heading}\")]]")
  end

  def subfields(field)
    field.xpath('marc:subfield').map { |subfield| [subfield['code'], subfield.content] }
  end

  around do |example|
    FileUtils.rm_f(%w[MARC_out.xml log_out.txt])
    example.run
    FileUtils.rm_f(%w[MARC_out.xml log_out.txt])
  end

  before do
    allow(job).to receive(:aspace_login) { job.instance_variable_set(:@client, client) }
    allow(job).to receive(:get_resource_uris_for_all_repos).and_return([resource_uri])
    allow(job).to receive(:sleep)
    allow(client).to receive(:get).with("#{resource_uri.sub('resources', 'resources/marc21')}.xml")
                                  .and_return(instance_double(ArchivesSpace::Response, body: fixture_xml))
    allow(client).to receive(:get).with(%r{top_containers/search}, anything)
                                  .and_return(instance_double(ArchivesSpace::Response, parsed: { 'response' => { 'docs' => [] } }))
    allow(Aspace2alma::AlmaDuplicateBarcodeCheck).to receive(:new)
      .and_return(instance_double(Aspace2alma::AlmaDuplicateBarcodeCheck, duplicate?: true))
    allow(Aspace2almaHelper).to receive(:rotate_file)
    allow(Aspace2almaHelper).to receive(:alma_sftp)
  end

  context 'with C1291, a collection with most of the common fields' do
    let(:fixture) { 'marc_c1291' }
    let(:resource_uri) { '/repositories/5/resources/3405' }

    it 'puts the bulk dates in parentheses in the 245 $g' do
      expect(doc.at_xpath("//marc:datafield[@tag='245']/marc:subfield[@code='g']").content).to eq('(mostly 1728-1809)')
    end

    it 'adds a 046 from the 008 dates' do
      expect(subfields(fields('046').first)).to eq([%w[a i], %w[c 1728], %w[e 1809]])
    end

    it 'adds a 982 for the physical location' do
      expect(fields('982').map { |tag982| subfields(tag982) }).to eq([[%w[c scamss]]])
    end

    it 'removes the fields Alma should not get' do
      %w[351 524 540 541 561 583 852].each do |tag|
        expect(fields(tag)).to be_empty, "expected no #{tag}"
      end
    end

    it 'trims subfields and collapses their whitespace' do
      expect(doc.xpath('//marc:subfield').map(&:content)).to all(satisfy { |text| text == text.squish })
    end

    it 'puts VIAF identifiers in $1 and drops record identifiers' do
      expect(subfields(field('600', 'Morris, Robert'))).to eq([['a', 'Morris, Robert'], ['1', 'http://viaf.org/viaf/68945505']])
      expect(subfields(field('700', 'Morris, Robert'))).to eq(
        [['a', 'Morris, Robert,'], ['e', 'associated name'], ['4', 'asn'], ['1', 'http://viaf.org/viaf/68945505']]
      )
    end

    it 'codes VIAF-sourced headings as LC headings even without an identifier' do
      tag610 = field('610', 'College of New Jersey')

      expect(tag610['ind2']).to eq('0')
      expect(subfields(tag610)).to eq([['a', 'College of New Jersey (Princeton, N.J.).']])
    end

    it 'keeps the source of local headings and adds $5' do
      tag610 = field('610', 'Philadelpia Society')

      expect(tag610['ind2']).to eq('7')
      expect(subfields(tag610).drop(1)).to eq([%w[2 local], %w[5 NjP]])
    end

    it 'splits headings at -- into subfields that follow the $a' do
      expect(subfields(field('651', 'Pennsylvania'))).to eq(
        [%w[a Pennsylvania], %w[x History], ['x', 'Colonial period, ca. 1600-1775.'], %w[v Sources]]
      )
      expect(subfields(field('655', 'Documents'))).to eq([%w[a Documents], ['y', '18th century'], %w[2 aat]])
    end

    it 'keeps the source of other thesauri' do
      tag655 = field('655', 'Correspondence')

      expect(tag655['ind2']).to eq('7')
      expect(subfields(tag655).last).to eq(%w[2 aat])
    end
  end

  context 'with GC186, a multilingual collection with LC identifiers' do
    let(:fixture) { 'marc_gc186' }
    let(:resource_uri) { '/repositories/11/resources/1477' }

    it 'keeps every language in the 041' do
      expect(fields('041').first.xpath("marc:subfield[@code='a']").map(&:content)).to eq(%w[eng fre ger dut jpn spa])
    end

    it 'keeps LC URIs in $0' do
      expect(subfields(field('650', 'Small presses'))).to eq(
        [['a', 'Small presses'], ['0', 'http://id.loc.gov/authorities/subjects/sh85077700']]
      )
    end

    it 'drops record identifiers on added entries' do
      expect(subfields(fields('710').first).map(&:first)).to eq(%w[a b b e 4])
    end

    it 'keeps the source of other thesauri' do
      expect(subfields(field('655', 'Proofs'))).to eq([['a', 'Proofs.'], %w[2 gmgpc]])
    end

    it 'passes text with XML special characters through unchanged' do
      source = Nokogiri::XML(fixture_xml).xpath("//*[@tag='520']/*[@code='a']").map { |subfield| subfield.content.squish }

      expect(fields('520').map { |tag520| tag520.at_xpath("marc:subfield[@code='a']").content }).to eq(source)
    end
  end

  context 'with TC132, a creator with a record identifier and a VIAF URI' do
    let(:fixture) { 'marc_tc132' }
    let(:resource_uri) { '/repositories/6/resources/1748' }

    it 'puts the VIAF URI in $1 and drops the record identifier' do
      expect(subfields(fields('100').first)).to eq(
        [['a', 'Jefferson, Joseph,'], %w[e creator], %w[4 cre], ['1', 'http://viaf.org/viaf/18419935']]
      )
    end

    it 'keeps 656s coded as _7 with $2 lcsh' do
      tag656 = fields('656').first

      expect(tag656['ind2']).to eq('7')
      expect(subfields(tag656).last).to eq(%w[2 lcsh])
    end
  end

  context 'with LAE064, an excluded collection' do
    let(:fixture) { 'marc_lae064' }
    let(:resource_uri) { '/repositories/8/resources/4120' }

    it 'leaves it out of the file' do
      expect(doc.xpath('//marc:record')).to be_empty
    end
  end

  context 'with ENG005, a collection without a start year' do
    let(:fixture) { 'marc_eng005' }
    let(:resource_uri) { '/repositories/9/resources/1505' }

    it 'adds no 046' do
      expect(doc.at_xpath("//marc:controlfield[@tag='008']").content[6..14]).to eq('s        ')
      expect(fields('046')).to be_empty
    end
  end

  context 'with ENG023, a collection without a creator' do
    let(:fixture) { 'marc_eng023' }
    let(:resource_uri) { '/repositories/9/resources/1496' }

    it 'exports it without a 1xx' do
      expect(doc.xpath('//marc:record').size).to eq(1)
      expect(doc.xpath("//marc:datafield[starts-with(@tag, '1')]")).to be_empty
    end
  end

  context 'with MC320, a subject URI from another LC service' do
    let(:fixture) { 'marc_mc320' }
    let(:resource_uri) { '/repositories/3/resources/4407' }

    it 'keeps it in $0' do
      expect(subfields(field('650', 'Macroeconomics'))).to eq([%w[a Macroeconomics], ['0', 'https://lccn.loc.gov/sh85079443']])
    end
  end

  context 'with C1064, a VIAF-sourced genre term' do
    let(:fixture) { 'marc_c1064' }
    let(:resource_uri) { '/repositories/5/resources/2809' }

    it 'codes it as an LC heading' do
      tag655 = field('655', 'Correspondence')

      expect(tag655['ind2']).to eq('0')
      expect(subfields(tag655)).to eq([%w[a Correspondence], ['y', '19th century']])
    end

    context 'when the record has no 856' do
      let(:fixture_xml) { file_fixture("aspace2alma/#{fixture}.xml").read.sub(%r{<datafield[^>]*tag="856".*?</datafield>}m, '') }

      it 'leaves it out of the file' do
        expect(doc.xpath('//marc:record')).to be_empty
      end
    end

    context 'when a subfield is blank' do
      let(:fixture_xml) do
        file_fixture("aspace2alma/#{fixture}.xml").read.sub(/(<datafield[^>]*tag="245"[^>]*>)/, '\1<subfield code="b">   </subfield>')
      end

      it 'removes it' do
        expect(fields('245').first.xpath("marc:subfield[@code='b']")).to be_empty
      end
    end

    context 'when added entries and less common subject tags have an LC-coded source' do
      let(:headings) do
        <<~XML
          <datafield ind1="1" ind2=" " tag="700"><subfield code="a">Sourced, Added Entry,</subfield><subfield code="0">https://viaf.org/viaf/555</subfield><subfield code="2">lcnaf</subfield></datafield>
          <datafield ind1="2" ind2="7" tag="611"><subfield code="a">Meeting Heading</subfield><subfield code="0">https://viaf.org/viaf/666</subfield><subfield code="2">viaf</subfield></datafield>
          <datafield ind1=" " ind2="7" tag="647"><subfield code="a">Event Heading</subfield><subfield code="2">lcsh</subfield></datafield>
          <datafield ind1=" " ind2="7" tag="648"><subfield code="a">20th century</subfield><subfield code="2">lcsh</subfield></datafield>
        XML
      end
      let(:fixture_xml) { file_fixture("aspace2alma/#{fixture}.xml").read.sub(/(\s*<datafield[^>]*tag="856")/, "\n#{headings}\\1") }

      it 'drops the source from added entries but keeps their second indicator' do
        tag700 = field('700', 'Sourced, Added Entry')

        expect(tag700['ind2']).to eq(' ')
        expect(subfields(tag700)).to eq([['a', 'Sourced, Added Entry,'], ['1', 'http://viaf.org/viaf/555']])
      end

      it 'codes them as LC headings' do
        expect(%w[611 647 648].map { |tag| [fields(tag).first['ind2'], subfields(fields(tag).first).map(&:first)] })
          .to eq([['0', %w[a 1]], ['0', %w[a]], ['0', %w[a]]])
      end
    end
  end

  context 'with RCPXG-5830371.1, a genre term ArchivesSpace already codes _0' do
    let(:fixture) { 'marc_rcpxg_5830371_1' }
    let(:resource_uri) { '/repositories/11/resources/1478' }

    it 'keeps it as it is' do
      tag655 = field('655', 'Postcards')

      expect(tag655['ind2']).to eq('0')
      expect(subfields(tag655)).to eq([%w[a Postcards], ['0', 'http://id.loc.gov/authorities/subjects/sh85105462']])
    end
  end

  context 'with C1756, a collection with a start year but no end year' do
    let(:fixture) { 'marc_c1756' }
    let(:resource_uri) { '/repositories/5/resources/4355' }

    it 'adds a 046 without $e' do
      expect(subfields(fields('046').first)).to eq([%w[a s], %w[c 1950]])
    end
  end

  context 'with C1715, a collection in several locations' do
    let(:fixture) { 'marc_c1715' }
    let(:resource_uri) { '/repositories/5/resources/4297' }

    it 'adds a 982 for each location code' do
      expect(fields('982').map { |tag982| subfields(tag982) }).to eq([[%w[c scamss]], [%w[c rcpxm]]])
    end
  end

  context 'with C0063, a collection with a scope note over the field size limit' do
    let(:fixture) { 'marc_c0063' }
    let(:resource_uri) { '/repositories/5/resources/3933' }

    it 'truncates the 520 to 7999 characters' do
      long_note = fields('520').map { |tag520| tag520.at_xpath("marc:subfield[@code='a']").content }.max_by(&:length)

      expect(long_note.length).to eq(7999)
      expect(long_note).to end_with('...')
    end
  end

  context 'with C1655, a locally sourced uniform title' do
    let(:fixture) { 'marc_c1655' }
    let(:resource_uri) { '/repositories/5/resources/4221' }

    it 'keeps the source and adds $5' do
      tag630 = fields('630').first

      expect(tag630['ind2']).to eq('7')
      expect(subfields(tag630)).to eq([['a', 'Quarterly review of literature (Princeton, N.J.)'], %w[2 local], %w[5 NjP]])
    end
  end

  context 'with C1777, names ArchivesSpace exports without a source' do
    let(:fixture) { 'marc_c1777' }
    let(:resource_uri) { '/repositories/5/resources/4383' }

    it 'leaves them as they are' do
      tag600 = field('600', 'Harrigan, Atlin')

      expect(tag600['ind2']).to eq('4')
      expect(subfields(tag600)).to eq([['a', 'Harrigan, Atlin,'], ['d', '1939-2005.']])
    end
  end

  context 'with MC284, a creator with an LC name URI' do
    let(:fixture) { 'marc_mc284' }
    let(:resource_uri) { '/repositories/3/resources/4300' }

    it 'keeps it in $0' do
      expect(subfields(fields('100').first)).to eq(
        [['a', 'Keeley, Robert V.,'], %w[e creator], ['0', 'http://id.loc.gov/authorities/names/n96068198']]
      )
    end
  end

  context 'with C0776, a collection excluded by its identifier' do
    let(:fixture) { 'marc_c0776' }
    let(:resource_uri) { '/repositories/5/resources/3991' }

    it 'leaves it out of the file' do
      expect(doc.xpath('//marc:record')).to be_empty
    end
  end
end
