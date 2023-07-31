# frozen_string_literal: true
module AlmaSubmitCollection
  class AlmaSubmitCollectionJob < LibJob
    def handle(data_set:)
      file_list = AlmaRecapFileList.new
      records_processed = 0
      file_list.file_contents.each do |file|
        processor = MarcFileProcessor.new(file:)
        processor.process
        records_processed += processor.records_processed
      end
      file_list.mark_files_as_processed
      data_set.data = "#{records_processed} records processed."
      data_set
    end
  end
end
