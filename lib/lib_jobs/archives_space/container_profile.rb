# frozen_string_literal: true

module LibJobs
  module ArchivesSpace
    class ContainerProfile < Object
      def self.parse_id(attributes)
        uri = attributes[:uri]
        segments = uri.split("/")
        segments.last
      end

      def generate_uri
        URI.join(client.config.base_uri, @values.uri)
      end

      attr_accessor :prefix
      attr_reader :name, :uri
      def initialize(attributes)
        @values = OpenStruct.new(attributes)

        @client = attributes[:client]

        @name = attributes[:name]

        @id = self.class.parse_id(attributes)
        @uri = generate_uri
      end

      def client
        @client
      end

      def attributes
        {
          id: @id,
          uri: @uri,
          name: @name,
          prefix: prefix
        }
      end
    end
  end
end
