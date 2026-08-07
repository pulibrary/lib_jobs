# frozen_string_literal: true
require 'dry-types'

module TMASGateCounts
  class Settings < Hanami::Settings
    setting :tmas_airtable_error_emails, constructor: Types::String
    setting :tmas_api_key, constructor: Types::String
  end
end
