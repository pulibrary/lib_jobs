# frozen_string_literal: true
require 'dry-types'

module WebEvents
  class Settings < Hanami::Settings
    setting :libcal_cid, constructor: Types::String, default: '12260'
    setting :libcal_k, constructor: Types::String, default: '79a5e62a54'
  end
end
