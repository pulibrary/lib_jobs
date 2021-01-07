# frozen_string_literal: true

module LibJobs
  module ArchivesSpace
    class Repository < Object
      def initialize(client:, id:)
        @client = client
        @id = id
      end

      def find_child(resource_class:, id:)
        response = @client.get("/repositories/#{@id}/#{resource_class.to_s.downcase.pluralize}/#{id}")
        return nil if response.status == 404

        resource_class.new(**response)
      end

      def find_resource(id:)
        find_child(resource_class: Resource, id: id)
      end

      def find_top_container(id:)
        find_child(resource_class: TopContainer, id: id)
      end

      def update_child(child)
        resource_class = child.class
        response = @client.post("/repositories/#{@id}/#{resource_class.to_s.downcase.pluralize}/#{child.id}", child.to_h)
        return nil if response.status == 400

        find_child(resource_class: child.class, id: child.id)
      end

      def update_top_container(top_container)
        update_child(top_container)
      end

      def update_resource(resource)
        update_child(resource)
      end

      def bulk_update_barcodes(update_values)
        response = @client.post("/repositories/#{@id}/top_containers/bulk/barcodes", update_values.to_h)
        return nil if response.status != 200 || !response[:id]

        find_resource(id: response[:id])
      end
    end
  end
end
