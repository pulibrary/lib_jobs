# frozen_string_literal: true
module AirTableStaff
  # This class is responsible for extracting information about
  # a person from the airtable staff directory JSON, according
  # to the mapping from the StaffDirectoryMapping class.
  class StaffDirectoryPerson
    include Deps['staff_directory_mapping', 'json_value_extractor']
    def call(json)
      staff_directory_mapping.fields.map do |field|
        json_value_extractor.call(field:, json:)
      end
    end
  end
end
