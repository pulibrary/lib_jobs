# frozen_string_literal: true
module AirTableStaff
  # This class is responsible for extracting a single
  # value from a json hash, based on the criteria in
  # the field hash
  class JSONValueExtractor
    def call(json:, field:)
      raw_value = json[field[:airtable_field_id]]
      transformer = field[:transformer]
      transformer ? transformer.call(raw_value) : raw_value
    end
  end
end
