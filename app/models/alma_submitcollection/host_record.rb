# frozen_string_literal: true

module AlmaSubmitcollection
  class HostRecord
    def constituent_records; end

    private

    def constituent_record_ids(record)
      constituent_ids = []
      record.fields('774').select { |f| f['w'] }.each do |field|
        next unless field['w'] =~ /^[^9]*99[0-9]+6421/

        id.gsub!(/^[^9]*(99[0-9]+6421).*$/, '\1')
        constituent_ids << id
      end
      constituent_ids
    end
  end
end
