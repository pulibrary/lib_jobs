# frozen_string_literal: true
module Aspace2alma
  # This class is responsible for accepting a MARC datafield that can be authorized (e.g. 100, 651) and creating
  # a new datafield from scratch that is based on the original data and meets our PUL standards.
  class NormalizeAuthorizedField
    # headings whose second indicator names the thesaurus
    THESAURUS_TAGS = %w[600 610 611 630 647 648 650 651 655].freeze

    # A temporary structure that we can use to hold the data we gather from an authorized field
    Field = Data.define(:tag, :ind1, :ind2, :subfield2, :identifiers, :subfields, :document) do
      def self.from_datafield(datafield)
        subfield2 = datafield.at_xpath('marc:subfield[@code="2"]')
        identifiers = datafield.xpath('marc:subfield[@code="0"]').map do |subfield0|
          MarcRules.authority_subfield(subfield0.content, subfield2&.content)
        end.compact
        new(tag: datafield['tag'], ind1: datafield['ind1'], ind2: datafield['ind2'], subfield2:, identifiers:,
            subfields: datafield.xpath('marc:subfield[not(@code="0")]'), document: datafield.document)
      end

      # Create a new Nokogiri field from scratch based on the data we have collected about the original (unnormalized) field
      def to_normalized_datafield
        datafield = Nokogiri::XML::Node.new('datafield', document)
        datafield['ind1'] = ind1
        datafield['ind2'] = lc_thesaurus? ? '0' : ind2
        datafield['tag'] = tag

        subfields.each do |subfield|
          datafield.add_child subfield.dup unless subfield['code'] == '2' && lc_thesaurus?
        end
        identifiers.select { it[0] }.uniq { it[1] }.each do |code, value|
          datafield.add_child "<subfield code='#{code}'>#{value}</subfield>"
        end
        datafield
      end

      def lc_thesaurus? = MarcRules.lc_source?(subfield2&.content) && (THESAURUS_TAGS.include?(tag) || !tag.start_with?('6'))
    end

    def call(original) = Field.from_datafield(original).to_normalized_datafield
  end
end
