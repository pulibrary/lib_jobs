# frozen_string_literal: true
module AlmaSubmitCollection
  # This class is responsible for reading files of MARC
  # records that we get from Alma, and writing processed
  # versions of those records to new files
  class MarcFileProcessor
    attr_reader :records_processed

    def initialize(file:, file_num: 1)
      @records_processed = 0
      @reader = MARC::XMLReader.new(file)
      @writer = MARC::XMLWriter.new(Tempfile.new(['scsb_submitcollection_std', "#{file_num}.marcxml"]))
      @constituent_writer = MARC::XMLWriter.new(constituent_record_file)
    end

    def process
      return if @records_processed.positive?

      # TODO: read files using nokogiri rather than rexml
      @reader.each do |record|
        recap_record = MarcRecord.new(record)
        next unless recap_record.valid?

        @writer.write(recap_record.record_fixes)
        recap_record.constituent_records.each { |constituent| @constituent_writer.write(constituent) }
        @records_processed += 1
      end
    end

    def constituent_record_file
      @constituent_record_file ||= Tempfile.new(['scsb_submitcollection_constituent'])
    end
  end
end