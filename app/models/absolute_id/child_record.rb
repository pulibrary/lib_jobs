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

  def json_properties
    super.merge({
                  repository_id: repository_id,
                  instances: json_object.instances
                })
  end
end
