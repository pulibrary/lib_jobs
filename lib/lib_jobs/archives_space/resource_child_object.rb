# frozen_string_literal: true
module LibJobs
  module ArchivesSpace
    class ResourceChildObject < ChildObject
      attr_reader :resource
      def initialize(attributes)
        super(attributes)

        @resource = @values.resource

        @level = @values.level
        @title = @values.title
      end

      def children
        @children ||= find_children
      end

      private

      def request_tree_root
        response = client.get("/repositories/#{repository.id}/resources/#{resource.id}/tree/node?node_uri=#{uri}")
        return if response.status.code == "404"

        response.parsed
      end

      def build_children_from(waypoints:)
        children = []

        waypoints.each_pair do |node_uri, paths|
          paths.each_pair do |path_index, path_attributes|
            path_attributes.each do |path|
              child_uri = path['uri']

              child = case path['jsonmodel_type']
                      when 'archival_object'
                        parent = if is_a?(LibJobs::ArchivesSpace::Resource)
                                   self
                                 else
                                   resource
                                 end
                        repository.find_archival_object(resource: parent, uri: child_uri)
                      else
                        repository.find_resource(uri: child_uri)
                      end

              children << child
            end
          end
        end

        children
      end

      def find_root_child_uris
        children = []
        response = request_tree_root
        return children if response.nil?

        waypoints = response['precomputed_waypoints']
        build_children_from(waypoints: waypoints)
      end

      def request_tree_node(node_uri)
        response = client.get("/repositories/#{repository.id}/resources/#{resource.id}/tree/node?node_uri=#{node_uri}")
        return if response.status.code == "404"

        response.parsed
      end

      def find_node_child_uris(node_uri)
        child_nodes = []
        response = request_tree_node(node_uri)
        return child_nodes if response.nil?

        waypoints = response['precomputed_waypoints']
        build_children_from(waypoints: waypoints)

        descendent_nodes = child_nodes.map { |child_node| find_node_child_uris(child_node.uri) }
        child_nodes + descendent_nodes.flatten
      end

      def find_children
        child_nodes = find_root_child_uris
        descendent_nodes = child_nodes.map { |child_node| find_node_child_uris(child_node.uri) }
        child_nodes + descendent_nodes.flatten
      end
    end
  end
end
