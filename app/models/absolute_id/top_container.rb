# frozen_string_literal: true
class AbsoluteId::TopContainer < AbsoluteId::ChildRecord
  def self.resource_class
    LibJobs::ArchivesSpace::TopContainer
  end

  def properties
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
