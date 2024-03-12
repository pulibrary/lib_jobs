# frozen_string_literal: true

module AlmaSubmitCollection
  # This class is responsible for requesting
  # MARC records from the Alma API
  class AlmaApi
    def initialize
      @conn = Faraday.new(LibJobs.config[:alma_region]) do |faraday|
        faraday.request   :url_encoded
        faraday.response  :logger, nil, { headers: true, bodies: false }
        faraday.adapter   Faraday.default_adapter
      end
    end

    # Fetch the bib records from the Alma API
    # Returns an array of MARCXML records
    def fetch_marc_records(mms_ids)
      return [] if mms_ids.empty?
      doc = Nokogiri::XML(bib_record_call(mms_ids).body)
      xml_to_bibs doc
    end

    def bib_record_call(mms_ids)
      @conn.get do |req|
        req.url 'almaws/v1/bibs'
        req.headers['Content-Type'] = 'application/xml'
        req.headers['Accept'] = 'application/xml'
        req.params['apikey'] = LibJobs.config[:alma_bib_api_key]
        req.params['mms_id'] = mms_ids.join(',')
      end
    end

    private

    # Returns an array of MARCXML records
    def xml_to_bibs(doc)
      doc.xpath('//bib//record').map do |record|
        Tempfile.create do |valid_record|
          MarcCollection.from_record_string(record.to_xml).write(valid_record)
          reader = MARC::XMLReader.new valid_record.path, parser: 'nokogiri'
          reader.first
        end
      end
    end
  end
end
