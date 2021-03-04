# frozen_string_literal: true
class AbsoluteId::ChildRecord < AbsoluteId::Record
  self.abstract_class = true

  def repository_id
    @repository_id ||= parse_repository_id
  end

  def parse_repository_id
    return unless uri.include?('repositories')

    segments = uri.split('/repositories/')
    last_segment = segments.last
    sub_segments = last_segment.split('/')
    sub_segments.first
  end

  def properties
    super.merge({
      instances: json_object.instances,
      child_uris: json_object.child_uris # This enables the caching of children, ensuring that this becomes a tree
    })
  end

  def to_resource
    resource_attributes = properties
    resource_attributes[:repository_id] = repository_id

    self.class.resource_class.new(resource_attributes)
  end
end
