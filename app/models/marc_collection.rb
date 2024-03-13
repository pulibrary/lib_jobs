# frozen_string_literal: true

# Takes MARC records from Alma as IO,
# does the necessary cleanup,
# and then can write the results to
# IO
class MarcCollection
  attr_reader :document
  def initialize(document)
    @document = document
  end

  def write(io)
    Rails.logger.debug('Parsing an XML file and adding the namespace')
    parser = Nokogiri::XML::SAX::Parser.new(MarcCollectionDocumentCallbacks.new(io))
    io.write "<?xml version=\"1.0\"?>\n"
    parser.parse document

    io.close
    io
  end

  # An alternative initializer, if you just have a
  # single record without the MARCXML namespace,
  # as you might when getting a response from the
  # Alma API
  def self.from_record_string(string)
    document = Tempfile.new
    document.write "<collection>#{string}</collection>"
    document.rewind
    MarcCollection.new document
  end
end
