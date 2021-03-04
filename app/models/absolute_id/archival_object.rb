# frozen_string_literal: true
class AbsoluteId::ArchivalObject < AbsoluteId::ChildRecord
  def self.resource_class
    LibJobs::ArchivesSpace::ArchivalObject
  end

  def properties
    super.merge({
      ref_id: json_object.ref_id,
      title: json_object.title,
      level: json_object.level
    })
  end

  # This might not need to be overwritten
  def to_resource
    resource_attributes = properties

    self.class.resource_class.new(resource_attributes)
  end
end
