# frozen_string_literal: true
class AbsoluteId::Repository < AbsoluteId::Record
  def self.resource_class
    LibJobs::ArchivesSpace::Repository
  end

  def json_properties
    super.merge({
      name: json_object.name,
      repo_code: json_object.repo_code
    })
  end
end
