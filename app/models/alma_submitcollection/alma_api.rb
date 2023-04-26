# frozen_string_literal: true

module AlmaSubmitcollection
  class AlmaApi
    def initialize
      @conn = Faraday.new(LibJobs.config[:alma_api_uri]) do |faraday|
        faraday.request   :url_encoded
        faraday.response  :logger, nil, { headers: true, bodies: false }
        faraday.adapter   Faraday.default_adapter
      end
    end

    def bib_record_call(mms_ids)
      @conn.get do |req|
        req.url 'almaws/v1/bibs'
        req.headers['Content-Type'] = 'application/xml'
        req.headers['Accept'] = 'application/xml'
        req.params['apikey'] = LibJobs.config[:alma_api_key]
        req.params['mms_id'] = mms_ids.join(',')
      end
    end
  end
end
