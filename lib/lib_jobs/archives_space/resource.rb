# frozen_string_literal: true
module LibJobs
  module ArchivesSpace
    class Resource < ResourceChildObject
      attr_reader :ead_id, :title
      def initialize(attributes)
        super(attributes)

        @ead_id = @values.ead_id
      end

      def attributes
        super.merge({
          ead_id: ead_id,
          title: title,
        })
      end

      def instances
        instance_values = @values.to_h
        persisted = instance_values.fetch(:instances, [])
        persisted.map { |instance_attributes| Instance.new(instance_attributes.merge(repository: repository)) }
      end

      def instances=(updated)
        instance_values = updated.map(&:to_h)
        @values.instances = instance_values
      end

      def request_tree_root
        response = client.get("/repositories/#{repository.id}/resources/#{@id}/tree/root")
        return if response.status.code == "404"

        response.parsed
      end

      def request_tree_node(node_uri)
        response = client.get("/repositories/#{repository.id}/resources/#{@id}/tree/node?node_uri=#{node_uri}")
        return if response.status.code == "404"

        response.parsed
      end

      def top_containers
        child_containers = instances.map(&:top_container)
        child_containers + children.map { |child| child.top_containers }.flatten
      end

      def search_top_containers(indicator:)
        top_containers.select do |container|
          #  !container.collection.empty? && container.collection.identifier == resource_title && container.indicator == indicator
          container.indicator == indicator
        end
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
