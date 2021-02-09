
# frozen_string_literal: true
module LibJobs
  module ArchivesSpace
    class Object
      def self.parse_id(attributes)
        uri = attributes[:uri]
        segments = uri.split("/")
        segments.last
      end

      attr_reader :id, :client, :lock_version, :uri
      def initialize(attributes)
        normalized = attributes.deep_symbolize_keys
        @values = OpenStruct.new(normalized)
        @client = @values.client
        @lock_version = @values.lock_version

        @id = self.class.parse_id(attributes)
        @uri = generate_uri
      end

      def attributes
        @values.to_h
      end

      def to_h
        attributes
      end

      def as_json(**_options)
        attributes
      end

      def eql?(other)
        return false unless id === other.id

        attributes === other.attributes
      end

      private

      def generate_uri
        URI.join(client.config.base_uri, @values.uri)
      end
    end
  end
end
