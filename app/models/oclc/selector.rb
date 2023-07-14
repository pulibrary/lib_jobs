# frozen_string_literal: true

module Oclc
  class Selector
    attr_reader :selector_config
    def initialize(selector_config:)
      @selector_config = selector_config
    end

    def name
      selector_config.keys.first.to_s
    end

    def call_number_ranges
      selector_config[selector_key][:classes]
    end

    def classes
      call_number_ranges.pluck(:class).uniq
    end

    def subjects
      selector_config[selector_key][:subjects]
    end

    def selector_key
      selector_config.keys.first
    end
  end
end
