# frozen_string_literal: true
module AirTableStaff
  # This class is responsible for extracting information about
  # a person from the airtable staff directory JSON, according
  # to the mapping from the StaffDirectoryMapping class.
  class StaffDirectoryPerson
    def initialize(json)
      @json = json
      @mapping = StaffDirectoryMapping.new
    end

    def to_a
      @array_version ||= mapping.fields.map do |field|
        JsonValueExtractor.new(field:, json:).extract
      end
    end

    private

    attr_reader :json, :mapping
  end
end
