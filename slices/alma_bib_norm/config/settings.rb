# frozen_string_literal: true
require 'dry-types'

module AlmaBibNorm
  class Settings < Hanami::Settings
    setting :alma_bib_norm_error_recipients, constructor: Types::String
  end
end
