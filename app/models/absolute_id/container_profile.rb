# frozen_string_literal: true
class AbsoluteId::ContainerProfile < AbsoluteId::Record
  def self.resource_class
    LibJobs::ArchivesSpace::ContainerProfile
  end

  def attributes
    super.merge({
      name: json_resource.name,
      prefix: json_resource.prefix
    })
  end
end
