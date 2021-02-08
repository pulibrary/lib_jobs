# frozen_string_literal: true

module LibJobs
  module ArchivesSpace
    class Location < Object
      def self.parse_id(attributes)
        uri = attributes[:uri]
        segments = uri.split("/")
        segments.last
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

      def client
        @client
      end

      def generate_uri
        URI.join(client.config.base_uri, @values.uri)
      end

      def attributes
        {
          building: @building,
          classification: @classification,
          id: @id,
          uri: @uri
        }
      end

      def ref
        segments = @uri.to_s.split('/')
        output = segments[(-2..-1)].join('/')
        "/#{output}"
      end

      def start_date
        create_time = @values.create_time
        segments = create_time.split('T')
        segments.first
      end

      def to_container_ref
        {
          jsonmodel_type: 'container_location',
          status: 'current',
          start_date: start_date,
          system_mtime: @values.system_mtime,
          user_mtime: @values.user_mtime,
          ref: ref
        }
      end

      def eql?(other)
        return false unless id === other.id

        attributes === other.attributes
      end

      def update
        repository.update_child(self)
      end
    end
  end
end
