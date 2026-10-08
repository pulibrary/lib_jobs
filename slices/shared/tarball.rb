# frozen_string_literal: true

require 'rubygems/package'
require 'zlib'

# take some .tar.gz IO (File, Net::SFTP::Operations::File, StringIO,
# or similar) and make its uncompressed contents available as an
# array of Tempfile objects
module Shared
  class Tarball
    def contents(file)
      untar(file).map do |entry|
        next unless entry.file?
        tempfile = Tempfile.new(binmode: true)
        while (chunk = entry.read(10))
          tempfile.write chunk
        end
        tempfile.rewind
        tempfile
      end.compact
    end

    private

    def untar(file)
      unzipped = Zlib::GzipReader.new(file)
      Gem::Package::TarReader.new unzipped
    end
  end
end
