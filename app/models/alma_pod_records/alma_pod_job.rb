# frozen_string_literal: true
module AlmaPodRecords
  class AlmaPodJob < LibJob
    def initialize
      @files_to_send = fetch_and_clean_files
    end

    private
    def fetch_and_clean_files
      documents = AlmaPodFileList.new.documents
      documents.map do |document|
        filename = "#{rand}.testing.xml"
        document.each { |node| node.default_namespace = 'http://www.loc.gov/MARC21/slim' }
        File.write(filename, document.to_xml)
      end
    end
  end
end
