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

      def attributes
        super.merge({
                      title: title,
                      level: level,
                      instances: @instance_properties,
                      top_containers: @top_containers
                    })
      end

      def resolve_top_containers
        repository.search_top_container_children_by(collection: ead_id)
      end

      def top_containers
        @top_containers ||= resolve_top_containers
      end
    end
  end
end
