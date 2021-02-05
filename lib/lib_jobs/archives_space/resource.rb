# frozen_string_literal: true
module LibJobs
  module ArchivesSpace
    class Resource < Object
      def self.parse_id(attributes)
        uri = attributes[:uri]
        segments = uri.split("/")
        segments.last
      end

      def generate_uri
        path = @values.uri
        URI.join(@repository.uri, path)
      end

      attr_reader :title
      def initialize(_client, attributes)
        super(attributes)

        @id = self.class.parse_id(attributes)
        @uri = generate_uri
        @title = @values.title
        @ead_id = @values.ead_id
      end

      def attributes
        {
          id: @id,
          uri: @uri,
          title: @title
        }
      end

      def instances
        @values.instances.map { |instance_attributes| Instance.new(instance_attributes.merge(repository: @repository)) }
      end

      def instances=(updated)
        instance_values = updated.map(&:to_h)
        @values[:instances] = instance_values
      end

      def top_containers
        instances.map(&:top_container)
      end

      def barcodes
        top_containers.map(&:barcode)
      end

      def barcodes=(updated)
        bulk_values = top_containers.map do |top_container|
          {
            top_container.id => updated.barcode.value
          }
        end

        @repository.bulk_update_barcodes(bulk_values)
      end

      def update
        top_containers.each(&:update)
        super
      end
    end
  end
end
