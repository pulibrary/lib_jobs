# frozen_string_literal: true

module LibJobs
  module ArchivesSpace
    class TopContainer < Object
      # def barcode
      #  return unless @values[:barcode]

      #  @barcode ||= AbsoluteId.find_or_initialize_by(value: @values[:barcode])
      # end

      # def barcode=(updated)
      #  @value[:barcode] = updated.value
      # end

      def self.parse_id(attributes)
        uri = attributes[:uri]
        segments = uri.split("/")
        segments.last
      end

      def generate_uri
        path = @values.uri
        URI.join(@repository.uri, path)
      end

      def initialize(attributes)
        super(attributes)

        @id = self.class.parse_id(attributes)
        @uri = generate_uri
      end

      def barcode
        @values[:barcode]
        @values.barcode
      end

      def indicator
        @values[:indicator]
        @values.indicator
      end

      def attributes
        {
          id: @id,
          uri: @uri,
          barcode: barcode,
          indicator: indicator
        }
      end
    end
  end
end
