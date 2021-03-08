# frozen_string_literal: true
class AbsoluteId::TopContainer < AbsoluteId::ChildRecord
  def self.resource_class
    LibJobs::ArchivesSpace::TopContainer
  end

  has_and_belongs_to_many :archival_objects, join_table: 'archival_objects_top_containers'
  has_and_belongs_to_many :resources, join_table: 'resources_top_containers'
  def json_properties
    super.merge({
      active_restrictions: json_object.active_restrictions,
      barcode: json_object.barcode,
      collection: json_object.collection,
      container_locations: json_object.locations,
      exported_to_ils: json_object.exported_to_ils,
      ils_holding_id: json_object.ils_holding_id,
      ils_item_id: json_object.ils_item_id,
      indicator: json_object.indicator,
      series: json_object.series,
      type: json_object.type
    })
  end
end
