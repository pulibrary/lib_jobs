# frozen_string_literal: true
class AbsoluteId::Resource < AbsoluteId::Record
  def self.resource_class
    LibJobs::ArchivesSpace::Resource
  end

  def attributes
    super.merge({
      title: json_resource.title
    })
  end
end
