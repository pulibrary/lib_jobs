# frozen_string_literal: true
class AbsoluteId::ArchivalObject < AbsoluteId::ResourceChildRecord
  def self.resource_class
    LibJobs::ArchivesSpace::ArchivalObject
  end

  has_and_belongs_to_many :top_containers, join_table: 'archival_objects_top_containers'
  def properties
    super.merge({
      ref_id: json_object.ref_id,
      title: json_object.title,
      level: json_object.level
    })
  end
end
