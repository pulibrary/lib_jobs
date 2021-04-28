# frozen_string_literal: true
module LibJobs
  module ArchivesSpace
    class ResourceChildObject < ChildObject
      attr_accessor :resource, :title, :level
      def initialize(attributes)
        super(attributes)

        @resource = @values.resource

        @instance_properties = @values.instances || []
        @children = @values.children
        @top_containers = @values.top_containers

        @level = @values.level
        @title = @values.title
      end

      def instances
        @instances ||= @instance_properties.map do |props|
          instance_attributes = props.merge(repository: repository)
          Instance.new(instance_attributes)
        end
      end

      def instances=(updated)
        @instances = nil
        @instance_properties = updated
        instances
      end

      def attributes
        super.merge({
                      title: title,
                      level: level,
                      instances: @instance_properties,
                      top_containers: @top_containers
                    })
      end

      def resolve_children
        @resolved_children ||= find_children
      end

      def children
        @children ||= resolve_children
      end

      def resolve_top_containers
        @resolved_top_containers ||= find_top_containers
      end

      def top_containers
        @top_containers ||= resolve_top_containers
      end

      def cache
        super
      end

      private

      def child_uris
        []
      end

      def container_uris
        @container_uris ||= top_containers.map(&:uri)
      end

      def build_children_from(waypoints:)
        children = []

        waypoints.each_pair do |_node_uri, paths|
          paths.each_pair do |_path_index, path_attributes|
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

      def find_root_children
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
      rescue StandardError => error
        Rails.logger.warn("Failed to retrieve the tree root node data for #{node_uri}: #{error}")
        nil
      end

      def find_node_children(node_uri)
        child_nodes = []
        response = request_tree_node(node_uri)
        return child_nodes if response.nil?

        waypoints = response['precomputed_waypoints']
        child_nodes = build_children_from(waypoints: waypoints)

        descendent_nodes = child_nodes.map { |child_node| find_node_children(child_node.uri) }
        child_nodes + descendent_nodes.flatten
      end

      def find_top_containers
        repository.search_top_container_children_by(collection: ead_id)
      end

      def deprecated_find_top_containers
        raise(StandardError, "This is deprecated")
      end
    end
  end
end
