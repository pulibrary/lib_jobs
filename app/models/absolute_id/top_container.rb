# frozen_string_literal: true
class AbsoluteId::TopContainer < AbsoluteId::Record
  def self.resource_class
    LibJobs::ArchivesSpace::TopContainer
  end

  def attributes
    super.merge({
      active_restrictions: active_restrictions,
      barcode: barcode,
      collection: collection,
      container_locations: locations,
      exported_to_ils: exported_to_ils,
      ils_holding_id: ils_holding_id,
      ils_item_id: ils_item_id,
      indicator: indicator,
      series: series,
      type: type
    })
  end
end
