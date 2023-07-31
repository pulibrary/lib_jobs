# frozen_string_literal: true
module AlmaSubmitCollection
  # This class is responsible for accepting
  # a reasonable amount of MARC data
  # and writing it to a file in an S3 bucket
  class MarcS3Writer
    attr_reader :filenames_on_disk
    def initialize(records_per_file: 10_000, file_type: 'std')
      @filenames_on_disk = []
      @records_in_file = 0

      @records_per_file = records_per_file
      @file_type = file_type
    end

    def write(record)
      marc_writer.write record
      @records_in_file += 1
    end

    def marc_writer
      if @marc_writer
        return @marc_writer unless full
        @marc_writer.close
      end
      new_file = Tempfile.new(filename_components)
      @marc_writer = MARC::XMLWriter.new(new_file)
      filenames_on_disk << new_file.path
      @records_in_file = 0
      @marc_writer
    end

    def done
      @marc_writer&.close
    end

    private

    def filename_components
      components = ["scsb_submitcollection_#{@file_type}"]
      components << "#{Time.current.iso8601}.marcxml"
      components
    end

    def full
      @records_in_file >= @records_per_file
    end
  end
end
