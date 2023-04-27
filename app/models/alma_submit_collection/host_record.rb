# frozen_string_literal: true

module AlmaSubmitCollection
  class HostRecord
    def initialize(record)
      @record = record
    end

    def constituent_records
      ids = constituent_record_ids(@record)
      AlmaApi.new.bib_record_call(ids)
    end

    private

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
