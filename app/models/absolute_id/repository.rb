# frozen_string_literal: true
class AbsoluteId::Repository < AbsoluteId::Record
  def self.resource_class
    LibJobs::ArchivesSpace::Repository
  end
end
