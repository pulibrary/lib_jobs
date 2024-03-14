# frozen_string_literal: true
# This class is responsible for defining the callbacks that
# a Nokogiri SAX parser must call when it encounters certain
# events within a MarcXML document from Alma
class MarcCollectionDocumentCallbacks < Nokogiri::XML::SAX::Document
  def initialize(io)
    super()
    @io = io
  end

  # Write the opening tag for an element
  def start_element(name, attrs = [])
    # If this is the root <collection> node, and it doesn't already
    # have the required MARC namespace, add it
    attrs << ['xmlns', 'http://www.loc.gov/MARC21/slim'] if name == 'collection' && attrs.none? { |attr| attr[0] == 'xmlns' }
    attr_strings = attrs.map { |attr| "#{attr[0]}=\"#{attr[1]}\"" }
    @io.write('<')
    @io.write(name)
    if attr_strings.any?
      @io.write(' ')
      @io.write attr_strings.join(' ')
    end
    @io.write('>')
  end

  # Write any text that can be found in an open tag
  def characters(string)
    @io.write string.encode!(xml: :text)
  end

  # Write the closing tag for an element
  def end_element(name)
    @io.write "</#{name}>"
  end

    private

  def valid_marcxml_tag?(tag)
    %w[record collection leader controlfield datafield subfield].include? tag
  end
end
