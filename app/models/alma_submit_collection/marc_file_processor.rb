# frozen_string_literal: true
module AlmaSubmitCollection
  # This class is responsible for reading files of MARC
  # records that we get from Alma, and writing processed
  # versions of those records to new files
  class MarcFileProcessor
    attr_reader :records_processed

    def initialize(file:)
      @records_processed = 0
      normalized_records = StringIO.new
      MarcCollection.new(file).write(normalized_records)
      @reader = MARC::XMLReader.new(normalized_records.reopen(normalized_records.string, 'r'), parser: "nokogiri")
      @writer = MarcS3Writer.new(records_per_file: 10_000)
      @constituent_writer = MarcS3Writer.new(records_per_file: 1_000, file_type: 'constituent')
    end

    def process
      return if @records_processed.positive?

      @reader.each do |record|
        recap_record = MarcRecord.new(record)
        next unless recap_record.valid?

        writer = recap_record.constituent_records.any? ? @constituent_writer : @writer
        writer.write(recap_record.version_for_recap)
        recap_record.constituent_records.each { |constituent| @constituent_writer.write(constituent) }
        @records_processed += 1
      end
      @writer.done
      @constituent_writer.done
    end

    def constituent_record_filenames
      @constituent_writer.filenames_on_disk
    end
  end
end
