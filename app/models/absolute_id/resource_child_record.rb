# frozen_string_literal: true
class AbsoluteId::ResourceChildRecord < AbsoluteId::ChildRecord
  self.abstract_class = true

  def self.build_from_resource(resource)
    resource_attributes = resource.attributes.deep_dup

    resource_attributes.delete(:children)
    resolved_children = resource.resolve_children
    #children = child_resources.map(&:find_or_create_model)

    resource_attributes.delete(:top_containers)
    resolved_containers = resource.resolve_top_containers
    top_containers = resolved_containers.map(&:find_or_create_model)

    uri = resource.uri.to_s
    json_resource = JSON.generate(resource_attributes)

    #new(uri: uri, children: children, top_containers: top_containers, json_resource: json_resource)
    new(uri: uri, top_containers: top_containers, json_resource: json_resource)
  end

  # Temporary
  def children
    top_containers
  end

  def json_properties
    super.merge({
      children: children.map(&:to_resource),
      top_containers: top_containers.map(&:to_resource)
    })
  end
end
