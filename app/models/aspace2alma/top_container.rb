# frozen_string_literal: true
module Aspace2alma
  # A class to manipulate an ArchivesSpace top_container JSON record
  class TopContainer
    attr_reader :container_doc

    # def initialize(resource_uri, aspace_client, _file, _log_out, _remote_file)
    #   @resource_uri = resource_uri
    #   @aspace_client = aspace_client
    # end

    def initialize(container_doc)
      # instance variable = the thing that's passed in
      @container_doc = JSON.parse(container_doc['json'])
    end

    def location_code
      container_doc.dig('container_locations', 0, '_resolved', 'classification')
    end

    def at_recap?
      /^(sca)?rcp\p{L}+/.match?(location_code)
    end

    def barcode
      container_doc['barcode']
    end

    def valid?
      at_recap?
    end

    def item_record(tag099_a)
      <<~XML
        <datafield ind1=' ' ind2=' ' tag='949'>
          <subfield code='a'>#{container_doc['barcode']}</subfield>
          <subfield code='b'>#{container_doc['type']} #{container_doc['indicator']}</subfield>
          <subfield code='c'>#{location_code}</subfield>
          <subfield code='d'>(PULFA)#{tag099_a}</subfield>
        </datafield>
      XML
    end
  end
end
