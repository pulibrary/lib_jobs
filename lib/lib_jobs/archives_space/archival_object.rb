# frozen_string_literal: true
module LibJobs
  module ArchivesSpace
    class ArchivalObject < ResourceChildObject
      def self.model_class
        AbsoluteId::ArchivalObject
      end

      attr_reader :ref_id
      def initialize(attributes)
        super(attributes)

        @ref_id = @values.ref_id
      end

      def attributes
        super.merge({
                      ref_id: ref_id
                    })
      end

      private

      def request_tree_root
        response = client.get("/repositories/#{repository.id}/resources/#{resource.id}/tree/node?node_uri=#{uri}")
        return if response.status.code == "404"

        response.parsed
      rescue StandardError => error
        Rails.logger.warn("Failed to retrieve the tree root node data for #{uri}: #{error}")
        nil
      end

      def find_children
        child_nodes = find_root_children
        # descendent_nodes = child_nodes.map { |child_node| find_node_children(child_node.uri) }
        descendent_nodes = child_nodes.map(&:resolve_children)
        child_nodes + descendent_nodes.flatten
      end
    end
  end
end
