# frozen_string_literal: true
class AbsoluteId::Location < AbsoluteId::Record
  def self.resource_class
    LibJobs::ArchivesSpace::Location
  end

  def json_properties
    super.merge({
                  area: json_object.area,
                  barcode: json_object.barcode,
                  building: json_object.building,
                  classification: json_object.classification,
                  external_ids: json_object.external_ids,
                  floor: json_object.floor,
                  functions: json_object.functions,
                  room: json_object.room,
                  temporary: json_object.temporary
                })
  end
end
