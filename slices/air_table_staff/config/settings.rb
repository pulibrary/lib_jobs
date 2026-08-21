# frozen_string_literal: true
require 'dry-types'

module AirTableStaff
  class Settings < Hanami::Settings
    setting :airtable_token, constructor: Types::String
    setting :airtable_base_id, constructor: Types::String, default: 'appv7XA5FWS7DG9oe'
    setting :airtable_table_id, constructor: Types::String, default: 'tblM0iymGN5oqDUVm'
  end
end
