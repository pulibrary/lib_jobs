# frozen_string_literal: true
module AlmaSubmitCollection
  class MarcRecord
    attr_reader :record

    def initialize(record)
      @record = record
    end

    def valid?
      return false if @record.fields('852').none? { |field| alma_holding?(field) }
      return false if @record.fields('852').none? { |field| scsb_locations.include?(field['c'][0..1]) }
      return false if @record.fields('876').none? { |field| alma_item?(field) }

      true
    end

    def record_fixes
      @record.fields.delete_if { |f| f.tag =~ /[^0-9]/ }
      @record.fields.delete_if { |f| f.tag =~ /^9/ }
      @record.fields.delete_if { |f| %w[852 866 867 868 876].include?(f.tag) }
      @record.leader[5] = 'c' if @record.leader[5] == 'd'
      @record
    end

    def cgd_assignment
      return 'Committed' if committed_cgd?

      cgd_from_location(location)
    end

    def recap_item_info
      info_hash = {}
      info_hash[:customer_code] = customer_code
      info_hash[:use_restriction] = use_restriction
      info_hash
    end

    private

    def alma_holding?(field)
      /^22[0-9]+6421$/.match?(field['8']) ? true : false
    end

    def alma_item?(field)
      return false unless /^23[0-9]+06421$/.match?(field['a'])

      return false unless /^22[0-9]+06421$/.match?(field['0'])

      true
    end

    def scsb_locations
      %w[
        pw pl ql pt pb pf
        pn ps pj pz pk qk
        ph gp jq pa pe qv
        pm xc xg xm xn xp
        xr xw xx pg pv
      ]
    end

    def location
      wanted852['c']
    end

    def cgd_from_location(location)
      if %w[pa gp qk pf pv].include?(location)
        'Shared'
      else
        'Private'
      end
    end

    def retention_reasons
      %w[ReCAPItalianImprints IPLCBrill ReCAPSACAP]
    end

    def committed_cgd?
      f876 = @record.fields('876').select do |f|
        alma_item?(f)
      end
      f876.each do |field|
        return true if field['r'] == 'true' &&
                       retention_reasons.include?(field['s'])
      end
      false
    end

    def wanted852
      @record.fields('852').find do |f|
        alma_holding?(f)
      end
    end

    def customer_code
      case location[0..1]
      when /^x[a-z]$/
        'PG'
      when /^[^x][a-z]$/
        location.upcase
      end
    end

    def use_restriction
      case location[0..1]
      when 'pj', 'pk', 'pl', 'pm', 'pn', 'pt', 'pv'
        'In Library Use'
      when 'pb', 'ph', 'ps', 'pw', 'pz', 'xc', 'xg', 'xm', 'xn', 'xp', 'xr', 'xw', 'xx'
        'Supervised Use'
      end
    end
  end
end
