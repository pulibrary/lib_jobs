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

    def xml_to_bibs(doc)
      bibs = []
      doc.xpath('//bib').each do |bib|
        string = bib.to_xml
        reader = MARC::XMLReader.new(StringIO.new(string, 'r'))
        bibs << reader.first
      end
      bibs
    end
  end
end
