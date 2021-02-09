# frozen_string_literal: true
class AbsoluteId::Resource < AbsoluteId::Record
  def self.resource_class
    LibJobs::ArchivesSpace::Resource
  end
end
