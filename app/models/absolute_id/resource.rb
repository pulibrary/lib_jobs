# frozen_string_literal: true
class AbsoluteId::Resource < AbsoluteId::ChildRecord
  def self.resource_class
    LibJobs::ArchivesSpace::Resource
  end

  def properties
    super.merge({
      title: json_object.title
    })
  end
end
