# frozen_string_literal: true
class AbsoluteId::ResourceChildRecord < AbsoluteId::ChildRecord
  self.abstract_class = true

  def self.build_from_resource(resource)
    resource_attributes = resource.attributes.deep_dup

    children = resource_attributes[:children]
    binding.pry
    resource_attributes.delete(:children)

    top_containers = resource_attributes[:top_containers]
    resource_attributes.delete(:top_containers)

    uri = resource.uri.to_s
    json_resource = JSON.generate(resource_attributes)
    new(uri: uri, children: children, top_containers: top_containers, json_resource: json_resource)
  end

  # Temporary
  def children
    top_containers
  end

  def properties
    super.merge({
      children: children.map(&:to_json),
      top_containers: top_containers.map(&:to_json)
    })
  end
end
