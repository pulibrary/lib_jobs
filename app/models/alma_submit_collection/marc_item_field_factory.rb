# frozen_string_literal: true
module AlmaSubmitCollection
  # This class is responsible for creating a new
  # 876 MARC field (item), using data from
  # all existing 876 fields, library, and location
  class MarcItemFieldFactory
    def initialize(original_fields:, library:, location:)
      @original_fields = original_fields
      @library = library
      @location = location
    end

    def generate
      field = MARC::DataField.new('876', ' ', ' ')
      new_subfields.each { |subfield| field.append(subfield) }
      field
    end

    private

    def new_subfields
      [
        MARC::Subfield.new('0', @original_fields.first['0']), # holding_id
        MARC::Subfield.new('3', @original_fields.first['3']), # enum_chron
        MARC::Subfield.new('a', @original_fields.first['a']), # item_id
        MARC::Subfield.new('h', use_restriction),
        MARC::Subfield.new('j', 'Not Used'), # item status
        MARC::Subfield.new('k', @library),
        MARC::Subfield.new('l', 'RECAP'), # depository
        MARC::Subfield.new('p', @original_fields.first['p']),
        MARC::Subfield.new('t', @original_fields.first['t']),
        MARC::Subfield.new('x', cgd),
        MARC::Subfield.new('z', customer_code)
      ]
    end

    def cgd
      committed_cgd? ? 'Committed' : cgd_from_location
    end

    def cgd_from_location
      if %w[pa gp qk pf pv].include?(@location)
        'Shared'
      else
        'Private'
      end
    end

    def retention_reasons
      %w[ReCAPItalianImprints IPLCBrill ReCAPSACAP]
    end

    def committed_cgd?
      @original_fields.any? { |field| field['r'] == 'true' && retention_reasons.include?(field['s']) }
    end

    def recap_item_info
      info_hash = {}
      info_hash[:customer_code] = customer_code
      info_hash[:use_restriction] = use_restriction
      info_hash
    end

    def customer_code
      case @location[0..1]
      when /^x[a-z]$/
        'PG'
      when /^[^x][a-z]$/
        @location.upcase
      end
    end

    def use_restriction
      case @location[0..1]
      when 'pj', 'pk', 'pl', 'pm', 'pn', 'pt', 'pv'
        'In Library Use'
      when 'pb', 'ph', 'ps', 'pw', 'pz', 'xc', 'xg', 'xm', 'xn', 'xp', 'xr', 'xw', 'xx'
        'Supervised Use'
      end
    end
  end
end
