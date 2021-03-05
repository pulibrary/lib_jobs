# frozen_string_literal: true
class AbsoluteId::Resource < AbsoluteId::ResourceChildRecord
  def self.resource_class
    LibJobs::ArchivesSpace::Resource
  end

  has_and_belongs_to_many :top_containers, join_table: 'resources_top_containers'

  def properties
    super.merge({
      title: json_object.title
    })
  end
end
