# frozen_string_literal: true
module AlmaSubmitCollection
  class MarcRecord
    attr_reader :record

    def initialize(record)
      @record = record
    end

    def record_fixes
      @record.fields.delete_if { |f| f.tag =~ /[^0-9]/ }
      @record.fields.delete_if { |f| f.tag =~ /^9/ }
      @record.fields.delete_if { |f| %w[852 866 867 868 876].include?(f.tag) }
      @record.leader[5] = 'c' if record.leader[5] == 'd'
      @record
    end
  end
end
