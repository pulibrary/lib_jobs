# frozen_string_literal: true
module AirTableStaff
  # This class is responsible for extracting a single
  # value from a json hash, based on the criteria in
  # the field hash
  class JsonValueExtractor
    def initialize(json:, field:)
      @json = json
      @field = field
    end

    def extract
      raw_value = json[field[:airtable_field]]
      transformer = field[:transformer]
      transformer ? transformer.call(raw_value) : raw_value
    end

    private

    attr_reader :json, :field
  end
end
