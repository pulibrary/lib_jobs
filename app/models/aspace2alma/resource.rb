# frozen_string_literal: true
module Aspace2alma
  # A class to manipulate records from ASpace MarcXML
  class Resource
    attr_reader :resource_uri, :aspace_client

    def initialize(resource_uri, aspace_client, _file, _log_out)
      @resource_uri = resource_uri
      @aspace_client = aspace_client
    end

    def marc_uri
      "#{resource_uri.gsub('resources', 'resources/marc21')}.xml"
    end

    def marc_xml
      @marc_xml ||= Nokogiri::XML(aspace_client.get(marc_uri).body)
    end

    def tag008
      @tag008 ||= marc_xml.at_xpath('//marc:controlfield[@tag="008"]')
    end

    def tags040
      @tags040 ||= marc_xml.xpath('//marc:datafield[@tag="040"]')
    end

    def tag041
      @tag041 ||= marc_xml.at_xpath('//marc:datafield[@tag="041"]')
    end

    def tag099_a
      @tag099_a ||= marc_xml.at_xpath('//marc:datafield[@tag="099"]/marc:subfield[@code="a"]')
    end

    def tag245_g
      @tag245_g ||= marc_xml.at_xpath('//marc:datafield[@tag="245"]/marc:subfield[@code="g"]')
    end

    def tag351
      @tag351 ||= marc_xml.at_xpath('//marc:datafield[@tag="351"]')
    end

    def tags500
      @tags500 ||= marc_xml.xpath('//marc:datafield[@tag="500"]')
    end

    def tags500_a
      @tags500_a ||= marc_xml.xpath('//marc:datafield[@tag="500"]/marc:subfield[@code="a"]')
    end

    def tags520
      @tags520 ||= marc_xml.xpath('//marc:datafield[@tag="520"]')
    end

    def tags524
      @tags524 ||= marc_xml.xpath('//marc:datafield[@tag="524"]')
    end

    def tags535
      @tags535 ||= marc_xml.xpath('//marc:datafield[@tag="535"]')
    end

    def tags540
      @tags540 ||= marc_xml.xpath('//marc:datafield[@tag="540"]')
    end

    def tags541
      @tags541 ||= marc_xml.xpath('//marc:datafield[@tag="541"]')
    end

    def tags544
      @tags544 ||= marc_xml.xpath('//marc:datafield[@tag="544"]')
    end

    def tags561
      @tags561 ||= marc_xml.xpath('//marc:datafield[@tag="561"]')
    end

    def tags583
      @tags583 ||= marc_xml.xpath('//marc:datafield[@tag="583"]')
    end

    def tags852
      @tags852 ||= marc_xml.xpath('//marc:datafield[@tag="852"]')
    end

    def tag856
      @tag856 ||= marc_xml.at_xpath('//marc:datafield[@tag="856"]')
    end

    def tags6_7xx
      @tags6_7xx ||= marc_xml.xpath('//marc:datafield[@tag = "700" or @tag = "650" or
         @tag = "651" or @tag = "600" or @tag = "610" or @tag = "630" or @tag = "648" or
         @tag = "655" or @tag = "656" or @tag = "657"]')
    end

    def subfields
      @subfields ||= marc_xml.xpath('//marc:subfield')
    end

    # use node.attributes.blank? for all attributes
    def remove_empty_elements(node)
      node.children.map { |child| remove_empty_elements(child) }
      node.remove if node.content.blank? && (
      (node.attribute('@ind1').blank? && node.attribute('@ind2').blank?) ||
      node.attribute('@code').blank?)
    end

    # node is a Nokogiri::XML::Element
    def remove_linebreaks(node)
      node.xpath("//marc:subfield/text()").map do |text|
        text.content = text.content.gsub(/[\n\r]+/, " ")
      end
    end
  end
end
