# frozen_string_literal: true
module AlmaSubmitCollection
  class AlmaSubmitCollectionJob < LibJob
    def handle(data_set:)
      files = AlmaRecapFileList.new.file_contents
      records_processed = 0
      files.each_with_index do |file, file_num|
        processor = MarcFileProcessor.new(file:, file_num:)
        processor.process
        records_processed += processor.records_processed
      end
      data_set.data = "#{records_processed} records processed."
      data_set
    end
  end
end
