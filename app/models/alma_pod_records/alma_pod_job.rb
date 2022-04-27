# frozen_string_literal: true
module AlmaPodRecords
  class AlmaPodJob < LibJob
    attr_reader :documents

    def initialize(incoming_file_list: nil, file_pattern: '\.tar\.gz$', since: nil, directory: nil)
      super(category: 'AlmaPodRecords')
      since ||= Rails.application.config.pod.days_to_fetch.days.ago
      @file_list = incoming_file_list || AlmaPodFileList.new(file_pattern: file_pattern, since: since)
      @download_dir = Pathname.new(directory || Rails.application.config.pod.pod_record_path)
    end

    def handle(data_set:)
      send_files
      data_set
    end

    def send_files
      timestamp = Time.zone.now.strftime('%Y-%m-%d-%H-%M-%S')
      @file_list.documents.each_with_index do |document, index|
        filename = @download_dir + "pod_clean.#{timestamp}.#{index}.xml"
        MarcCollection.new(document).write(File.open(filename, 'w'))
        AlmaPodSender.new(filename: filename).send
      end
    end
  end
end
