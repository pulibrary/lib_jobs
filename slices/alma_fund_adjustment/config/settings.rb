# frozen_string_literal: true
require 'dry-types'

module AlmaFundAdjustment
  class Settings < Hanami::Settings
    setting :fund_adjustment_peoplesoft_input_dir, constructor: Types::String, default: '/tmp'
    setting :fund_adjustment_peoplesoft_input_file_pattern, constructor: Types::String, default: '\*.csv'
  end
end
