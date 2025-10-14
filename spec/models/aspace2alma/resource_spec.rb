# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Aspace2alma::Resource do
  let(:aspace_request) do
    stub_request(:get, "https://example.com/staff/api/repositories/3/resources/marc21/1511.xml")
      .and_return(status: 200, body: file_fixture('aspace2alma/marc_1511.xml'))
  end
  let(:resource_uri) { '/repositories/3/resources/1511' }
  let(:client) { ArchivesSpace::Client.new(ArchivesSpace::Configuration.new(base_uri: 'https://example.com/staff/api')) }
  let(:our_resource) { described_class.new(resource_uri, client, 'file', 'log_out') }
  before { aspace_request }
  it 'can be instantiated' do
    expect(described_class.new(resource_uri, client, 'file', 'log_out')).to be
  end

  describe '#marc_uri' do
    it 'has a uri' do
      expect(our_resource.marc_uri).to eq('/repositories/3/resources/marc21/1511.xml')
    end

    it 'can be run multiple times on the same resource' do
      expect(our_resource.marc_uri).to eq("/repositories/3/resources/marc21/1511.xml")
      expect(our_resource.marc_uri).to eq("/repositories/3/resources/marc21/1511.xml")
    end
  end

  describe '#marc_record' do
    it 'gets a marc record from the marc_uri' do
      expect(our_resource.marc_xml).to be_an_instance_of(Nokogiri::XML::Document)
      expect(our_resource.marc_xml.child.name).to eq('collection')
      expect(aspace_request).to have_been_made.once
    end
  end

  describe 'marc_fields' do
    it 'returns the corresponding MARC field' do
      expect(our_resource.tag008).to be_an_instance_of(Nokogiri::XML::Element)
      expect(our_resource.tag008.content).to eq("221215i19171950xx                  eng d")
    end
  end

  describe '#remove_empty_elements' do
    context 'with empty datafield' do
      let(:node) do
        xml = <<~XML
          <record>
            <datafield ind1=" " ind2=" " tag="049"/>
          </record>
        XML

        Nokogiri::XML(xml)
      end

      it 'removes empty elements' do
        expect(node.children).not_to be_empty
        our_resource.remove_empty_elements(node)
        expect(node.children).to be_empty
      end
    end
    context 'with non-empty datafield' do
      let(:node) do
        xml = <<~XML
          <record>
            <datafield ind1=" " ind2=" " tag="099">
              <subfield code="a">MC001.01</subfield>
            </datafield>
          </record>
        XML

        Nokogiri::XML(xml)
      end

      it 'does not remove populated elements' do
        expect(node.children).not_to be_empty
        our_resource.remove_empty_elements(node)
        expect(node.children).not_to be_empty
        expect(node.children.first.content).to eq('MC001.01')
      end
    end
    context 'with mix of empty and non-empty child nodes' do
      let(:node) do
        xml = <<~XML
          <record>
            <datafield ind1=" " ind2=" " tag="099">
              <subfield code="a">MC001.01</subfield>
              <subfield code="b"></subfield>
            </datafield>
          </record>
        XML

        Nokogiri::XML(xml)
      end

      it 'does not remove populated elements' do
        expect(node.children).not_to be_empty
        # newlines are counted as nodes
        expect(node.children.children.count).to eq(3)
        expect(node.children.children[1].children.count).to eq(5)
        our_resource.remove_empty_elements(node)
        expect(node.children.children.count).to eq(1)
        expect(node.children.children[0].children.count).to eq(1)
        expect(node.children).not_to be_empty
        expect(node.content).to eq('MC001.01')
      end
    end
  end

  describe 'remove linebreaks' do
    let(:node) do
      xml = <<~XML
        <datafield xmlns:marc="http://www.loc.gov/MARC21/slim" ><marc:subfield code="a">
          These Records document#{' '}
          the activities of the American Civil Liberties Union (ACLU) in protecting individual rights between 1947 and 1995.
          </marc:subfield></datafield>
      XML
      # this returns a Nokogiri::XML::Element
      Nokogiri.parse(xml).first_element_child
    end

    it 'removes hard linebreaks from text nodes' do
      expect(node.content.scan(/[\n\r]+/).size).to eq(3)
      our_resource.remove_linebreaks(node)
      expect(node.content.scan(/[\n\r]+/).size).to eq(0)
    end
  end
end
