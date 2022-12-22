# frozen_string_literal: true
module AlmaPodRecords
  class AlmaPodJob < LibJob
    attr_reader :documents

    def initialize(incoming_file_list: nil, file_pattern: '\.tar\.gz$', since: nil, directory: nil, compressed: false)
      super(category: 'AlmaPodRecords')
      since ||= Rails.application.config.pod.days_to_fetch.days.ago
      @file_list = incoming_file_list || AlmaPodFileList.new(file_pattern:, since:)
      @download_dir = Pathname.new(directory || Rails.application.config.pod.pod_record_path)
      @compressed = compressed
    end

    def handle(data_set:)
      send_files
      data_set
    end

    def send_files
      timestamp = Time.zone.now.strftime('%Y-%m-%d-%H-%M-%S')
      @file_list.files.each_with_index do |remote_filename, remote_index|
        @file_list.download_and_decompress_file(remote_filename).each_with_index do |contents, tarball_index|
          file_path = file_path(timestamp:, remote_index:, tarball_index:)
          write_file(file_path:, contents:)
          AlmaPodSender.new(filename: file_path, compressed: @compressed).send_to_pod
        end
      end
    end

    def file_path(timestamp:, remote_index:, tarball_index:)
      file_name = "pod_clean.#{timestamp}.#{remote_index}.#{tarball_index}.xml"
      file_name += '.gz' if @compressed
      @download_dir + file_name
    end

    def write_file(file_path:, contents:)
      if @compressed
        write_compressed_file(file_path:, contents:)
      else
        write_uncompressed_file(file_path:, contents:)
      end
    end

    def write_uncompressed_file(file_path:, contents:)
      MarcCollection.new(contents).write(File.open(file_path, 'w'))
    end

    def write_compressed_file(file_path:, contents:)
      Zlib::GzipWriter.open(file_path) do |gz|
        MarcCollection.new(contents).write(gz)
      end
    end
  end
end
