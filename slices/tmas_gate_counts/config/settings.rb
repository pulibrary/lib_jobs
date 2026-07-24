# frozen_string_literal: true
require 'dry-types'

module TMASGateCounts
  class Settings < Hanami::Settings
    setting :tmas_airtable_error_emails, constructor: Types::String
  end
end
