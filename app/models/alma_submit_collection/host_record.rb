# frozen_string_literal: true

module AlmaSubmitCollection
  class HostRecord < MarcRecord
    attr_reader :record

    def initialize(record)
      super(record)
      @record = record
    end

    def constituent_records
      ids = constituent_record_ids(@record)
      doc = Nokogiri::XML(AlmaApi.new.bib_record_call(ids).body)
      xml_to_bibs doc
    end

    private

    def constituent_record_ids(record)
      constituent_ids = []
      record.fields('774').select { |f| f['w'] }.each do |field|
        next unless /^[^9]*99[0-9]+6421/.match?(field['w'])

        id = field['w']
        id.gsub!(/^[^9]*(99[0-9]+6421).*$/, '\1')
        constituent_ids << id
      end
      constituent_ids
    end

    def xml_to_bibs(doc)
      bibs = []
      doc.xpath('//bib').each do |bib|
        string = bib.to_xml
        reader = MARC::XMLReader.new(StringIO.new(string, 'r'))
        bibs << reader.first
      end
      bibs
    end

    def alma_record
      @alma_record ||=
        begin
          new_record = MARC::Record.new
          AlmaSubmitCollection::MarcRecord.new(new_record)
        end
    end
  end
end
