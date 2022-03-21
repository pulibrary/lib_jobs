# frozen_string_literal: true

require 'rubygems/package'
require 'zlib'

# take a .tar.gz file (File object) and write its contents
# to disk or stream it in memory
class Tarball
  def initialize(file)
    @file = file
  end

  def contents
    @contents ||= untar.map do |entry|
      next unless entry.file?
      StringIO.new entry.read
    end.compact
  end

  private

  def untar
    z = Zlib::GzipReader.new(@file)
    unzipped = StringIO.new(z.read)
    z.close
    Gem::Package::TarReader.new unzipped
  end
end
