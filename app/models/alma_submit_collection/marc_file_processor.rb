# frozen_string_literal: true
module AlmaSubmitCollection
  # This class is responsible for reading files of MARC
  # records that we get from Alma, and writing processed
  # versions of those records to new files
  class MarcFileProcessor
    attr_reader :records_processed

    def initialize(file:, s3_partner:)
      @records_processed = 0
      Tempfile.create do |normalized_records|
        MarcCollection.new(file).write(normalized_records)
        @reader = MARC::XMLReader.new(normalized_records.path, parser: "nokogiri")
      end
      @writer = MarcS3Writer.new(records_per_file: 10_000, s3_partner:)
      @constituent_writer = MarcS3Writer.new(records_per_file: 1_000, file_type: 'constituent', s3_partner:)
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
  end
end
