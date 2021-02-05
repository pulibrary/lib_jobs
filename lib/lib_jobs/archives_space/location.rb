# frozen_string_literal: true

module LibJobs
  module ArchivesSpace
    class Location < Object
      def self.parse_id(attributes)
        uri = attributes[:uri]
        segments = uri.split("/")
        segments.last
      end

      def generate_uri
        URI.join(@client.config.base_uri, @values.uri)
      end

      attr_reader :uri
      def initialize(attributes)
        @values = OpenStruct.new(attributes)

        @client = attributes[:client]

        @building = attributes[:building]
        @floor = attributes[:floor]
        @room = attributes[:room]
        @area = attributes[:area]
        @barcode = attributes[:barcode]
        @temporary = attributes[:temporary]
        @classification = attributes[:classification]

        @id = self.class.parse_id(attributes)
        @uri = generate_uri
      end

      def attributes
        {
          building: @building,
          classification: @classification,
          id: @id,
          uri: @uri
        }
      end
    end
  end
end
