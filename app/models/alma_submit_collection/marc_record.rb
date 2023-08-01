# frozen_string_literal: true
module AlmaSubmitCollection
  # This class is responsible for
  # making various corrections and
  # edits necessary before we send
  # a MARC record to SCSB
  class MarcRecord
    def initialize(record, wanted852 = nil, wanted876 = nil, associated_holding_fields = nil)
      @record = record
      @wanted852 = wanted852 || @record.fields('852').find do |f|
        alma_holding?(f)
      end
      @wanted876 = wanted876 || @record.fields('876').select { |f| alma_item?(f) }
      @associated_holding_fields = associated_holding_fields || @record.fields(%w[583 866 867 868])
                                                                       .select { |field| alma_holding?(field) }
                                                                       .map { |field| MarcAssociatedHoldingFieldFactory.new(field).generate }
    end

    def valid?
      return false if @record.fields('852').none? { |field| alma_holding?(field) }
      return false if @record.fields('852').none? { |field| scsb_locations.include?(field['c'][0..1]) }
      return false if @record.fields('876').none? { |field| alma_item?(field) }

      true
    end

    def version_for_recap
      new_item_field = MarcItemFieldFactory.new(original_fields: @wanted876,
                                                library:,
                                                location:).generate
      new_location_field = MarcLocationFieldFactory.new(@wanted852).generate

      version_for_recap = record_fixes
      version_for_recap.append(new_location_field)
      @associated_holding_fields.each { |field| version_for_recap.append(field) }
      version_for_recap.append(new_item_field)
      version_for_recap
    end

    def record_fixes
      @record.fields.delete_if { |f| f.tag =~ /[^0-9]/ }
      @record.fields.delete_if { |f| f.tag =~ /^9/ }
      @record.fields.delete_if { |f| %w[852 866 867 868 876].include?(f.tag) }
      @record.leader[5] = 'c' if @record.leader[5] == 'd'
      MarcCleanup.empty_subfield_fix(@record)
      MarcCleanup.leaderfix(@record)
      MarcCleanup.extra_space_fix(@record)
      MarcCleanup.bad_utf8_fix(@record)
      MarcCleanup.invalid_xml_fix(@record)
      MarcCleanup.composed_chars_normalize(@record)
      MarcCleanup.tab_newline_fix(@record)
    end

    def constituent_records
      marc_records_from_api = AlmaApi.new.fetch_marc_records(constituent_record_ids(@record))
      marc_records_from_api.map do |record|
        recap_record = MarcRecord.new(record, @wanted852, @wanted876, @associated_holding_fields)
        recap_record.version_for_recap
      end
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

    def library
      @wanted852['b']
    end

    def location
      @wanted852['c']
    end

    def constituent_record_ids(record)
      constituent_ids = []
      record.fields('774').select { |f| f['w'] }.each do |field|
        next unless /^[^9]*99[0-9]+6421/.match?(field['w'])

        id = field['w']
        id.gsub!(/^[^9]*(99[0-9]+6421).*$/, '\1')
        constituent_ids << id
      end
      constituent_ids
    end
  end
end
