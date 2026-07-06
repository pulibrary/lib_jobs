# frozen_string_literal: true
require 'dry-types'

module OpenMarcRecords
  class Settings < Hanami::Settings
    setting :open_marc_records_location, constructor: Types::String
  end
end
