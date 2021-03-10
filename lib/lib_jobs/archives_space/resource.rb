# frozen_string_literal: true
module LibJobs
  module ArchivesSpace
    class Resource < ResourceChildObject
      def self.model_class
        AbsoluteId::Resource
      end

      attr_reader :ead_id
      def initialize(attributes)
        super(attributes)

        @ead_id = @values.ead_id
      end

      def attributes
        super.merge({
          ead_id: ead_id
        })
      end

      #def search_top_containers_by(indicator:, cache: true)
      def search_top_containers_by(index:, cache: true)
        if top_containers.empty?
          resolve_top_containers
          cache if cache
        end

        #related.select do |container|
        #  container.indicator == indicator
        #end
        sorted = top_containers.sort { |u, v| u.id <=> v.id }
        sorted[index]
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

      private

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

      def find_children
        child_nodes = find_root_children
        descendent_nodes = child_nodes.map { |child_node| child_node.resolve_children }
        child_nodes + descendent_nodes.flatten
      end

      # This does *not* recurse!
      def find_top_containers
        # Fix this
        super

        #response = client.get("/repositories/#{repository.id}/resources/#{@id}/top_containers")
        #return nil if response.status == 404

        #parsed = JSON.parse(response.body)
      end
    end
  end
end
