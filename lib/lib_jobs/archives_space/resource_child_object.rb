# frozen_string_literal: true
module LibJobs
  module ArchivesSpace
    class ResourceChildObject < ChildObject
      attr_accessor :resource, :title, :level
      def initialize(attributes)
        super(attributes)

        @resource = @values.resource
        # @resource_id = @resource.id unless @resource.nil?

        @child_uris = @values.child_uris
        @instance_properties = @values.instances || []

        @level = @values.level
        @title = @values.title
      end

      def children
        @children ||= begin
                        # This is needed for caching
                        if @child_uris.nil?
                          find_children
                        else
                          child_uris.map { |child_uri| repository.find_resource_child_object(resource: self, uri: child_uri) }
                        end
                      end
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

      def top_containers
        nodes = instances.map(&:top_container)

        nodes + children.map { |child| child.top_containers }.flatten
      end

      def attributes
        super.merge({
          title: title,
          level: level,
          instances: @instance_properties,
          child_uris: child_uris
        })
      end

      private

      # No memoization in order to enable caching
      def child_uris
        @child_uris ||= children.map(&:uri)
      end

      def request_tree_root
        response = client.get("/repositories/#{repository.id}/resources/#{resource.id}/tree/node?node_uri=#{uri}")
        return if response.status.code == "404"

        response.parsed
      rescue StandardError => standard_error
        Rails.logger.warn("Failed to retrieve the tree root node data for #{uri}")
        return
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
      rescue StandardError => standard_error
        Rails.logger.warn("Failed to retrieve the tree root node data for #{node_uri}")
        return
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

      def find_children
        child_nodes = find_root_children
        descendent_nodes = child_nodes.map { |child_node| find_node_children(child_node.uri) }
        child_nodes + descendent_nodes.flatten
      end
    end
  end
end
