# frozen_string_literal: true
class AbsoluteId::ContainerProfile < AbsoluteId::Record
  def self.resource_class
    LibJobs::ArchivesSpace::ContainerProfile
  end
end
