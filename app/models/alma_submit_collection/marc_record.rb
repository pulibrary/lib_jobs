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
  end
end
