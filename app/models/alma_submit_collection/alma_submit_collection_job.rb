# frozen_string_literal: true
module AlmaSubmitCollection
  class AlmaSubmitCollectionJob < LibJob
    def handle(data_set:)
      files = AlmaRecapFileList.new.file_contents
      records_processed = 0
      files.each_with_index do |file, file_num|
        # TODO: read files using nokogiri rather than rexml
        reader = MARC::XMLReader.new(file)
        writer = MARC::XMLWriter.new(Tempfile.new(['scsb_submitcollection_std', "#{file_num}.marcxml"]))
        reader.each do |record|
          writer.write(MarcRecord.new(record).record_fixes)
          records_processed += 1
        end
      end
      data_set.data = "#{records_processed} records processed."
      data_set
    end
  end
end
