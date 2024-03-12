# frozen_string_literal: true

require 'rubygems/package'
require 'zlib'

require 'objspace'

# take some .tar.gz IO (File, Net::SFTP::Operations::File, StringIO,
# or similar) and make its uncompressed contents available as an
# array of IO objects
class Tarball
  def initialize(file)
    @file = file
  end

  def contents
    @contents ||= untar.map do |entry|
      next unless entry.file?
      Tempfile.create(encoding: 'ascii-8bit') do |decompressed_tmp|
        decompressed_file = write_chunks(entry, decompressed_tmp)
        entry.close
        File.new decompressed_tmp.path
      end
    end.compact
  end

  private

  def untar
    unzipped = Zlib::GzipReader.new(@file)
    Gem::Package::TarReader.new unzipped
  end

  def write_chunks(entry, temp_file)
    while (chunk = entry.read(16 * 1024))
      temp_file.write chunk
    end
    temp_file.tap(&:rewind)
  end
end
