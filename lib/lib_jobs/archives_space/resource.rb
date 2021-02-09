# frozen_string_literal: true
module LibJobs
  module ArchivesSpace
    class Resource < ChildObject
      attr_reader :ead_id, :title
      def initialize(attributes)
        super(attributes)

        @title = @values.title
        @ead_id = @values.ead_id
      end

      def attributes
        {
          id: id,
          title: title,
          uri: uri
        }
      end

      def instances
        @values.instances.map { |instance_attributes| Instance.new(instance_attributes.merge(repository: repository)) }
      end

      def instances=(updated)
        instance_values = updated.map(&:to_h)
        @values.instances = instance_values
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

        repository.bulk_update_barcodes(bulk_values)
      end

      def update
        top_containers.each(&:update)
        super
      end
    end
  end
end
