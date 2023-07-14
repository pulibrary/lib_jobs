# frozen_string_literal: true
module AlmaSubmitCollection
  class MarcFileProcessor
    attr_reader :records_processed

    def initialize(file:, file_num: 1)
      @records_processed = 0
      @reader = MARC::XMLReader.new(file)
      @writer = MARC::XMLWriter.new(Tempfile.new(['scsb_submitcollection_std', "#{file_num}.marcxml"]))
    end

    def process
      return if @records_processed.positive?

      # TODO: read files using nokogiri rather than rexml
      @reader.each do |record|
        recap_record = MarcRecord.new(record)
        next unless recap_record.valid?

        @writer.write(recap_record.record_fixes)
        @records_processed += 1
      end
    end
  end
end
