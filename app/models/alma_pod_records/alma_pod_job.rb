# frozen_string_literal: true
module AlmaPodRecords
  class AlmaPodJob < LibJob
    attr_reader :documents

    def initialize(incoming_file_list: nil, file_pattern: '\.tar\.gz$', since: nil, directory: nil, compressed: false)
      super(category: 'AlmaPodRecords')
      since ||= Rails.application.config.pod.days_to_fetch.days.ago
      @file_list = incoming_file_list || AlmaPodFileList.new(file_pattern: file_pattern, since: since)
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
          file_path = @download_dir + "pod_clean.#{timestamp}.#{remote_index}.#{tarball_index}.xml"
          final_file_path = write_file(file_path: file_path, contents: contents, compressed: @compressed)
          AlmaPodSender.new(filename: final_file_path, compressed: @compressed).send_to_pod
        end
      end
    end

    def write_file(file_path:, contents:, compressed: false)
      if compressed
        write_compressed_file(file_path: file_path, contents: contents)
      else
        write_uncompressed_file(file_path: file_path, contents: contents)
      end
    end

    def write_uncompressed_file(file_path:, contents:)
      MarcCollection.new(contents).write(File.open(file_path, 'w'))
      file_path
    end

    def write_compressed_file(file_path:, contents:)
      compressed_file_path = file_path.to_path + '.gz'
      # write gzipped file
      Zlib::GzipWriter.open(compressed_file_path) do |gz|
        MarcCollection.new(contents).write(gz)
      end
      compressed_file_path
    end
  end
end
