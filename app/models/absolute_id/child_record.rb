# frozen_string_literal: true
class AbsoluteId::ChildRecord < AbsoluteId::Record
  self.abstract_class = true

  def repository_resource
    binding.pry
  end

  def to_resource
    resource_attributes = properties
    #resource_attributes[:client] = source_client
    #resource_attributes[:repository] = repository_resource

    self.class.resource_class.new(resource_attributes)
  end
end
