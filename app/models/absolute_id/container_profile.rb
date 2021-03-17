# frozen_string_literal: true
class AbsoluteId::ContainerProfile < AbsoluteId::Record
  def self.resource_class
    LibJobs::ArchivesSpace::ContainerProfile
  end

  def json_properties
    super.merge({
                  name: json_object.name,
                  prefix: json_object.prefix
                })
  end
end
