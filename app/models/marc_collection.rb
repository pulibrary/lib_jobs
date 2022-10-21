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
    xml = Nokogiri::XML(@document)
    xml.children.first.default_namespace = 'http://www.loc.gov/MARC21/slim'
    io.write(xml)
    io.close
    io
  end
end
