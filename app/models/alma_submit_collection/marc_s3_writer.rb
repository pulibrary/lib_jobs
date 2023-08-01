# frozen_string_literal: true
module AlmaSubmitCollection
  # This class is responsible for accepting
  # MARC data and writing it to files in an
  # AWS S3 bucket
  class MarcS3Writer
    attr_reader :filenames_on_disk
    def initialize(records_per_file: 10_000, file_type: 'std', s3_client: nil)
      @filenames_on_disk = []
      @records_in_file = 0

      @records_per_file = records_per_file
      @file_type = file_type
      @s3_client = s3_client || Aws::S3::Client.new(
        region: 'us-east-2',
        credentials: Aws::Credentials.new(
          ENV['SCSB_S3_PARTNER_ACCESS_KEY'],
          ENV['SCSB_S3_PARTNER_SECRET_ACCESS_KEY']
        )
      )
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
      @current_file = Tempfile.new(filename_components)
      @marc_writer = MARC::XMLWriter.new(@current_file)
      filenames_on_disk << @current_file.path
      @records_in_file = 0
      @marc_writer
    end

    def done
      return unless @marc_writer
      @marc_writer.close
      File.open(@current_file.path) do |file_contents|
        @s3_client.put_object(bucket: 'scsb', body: file_contents, key: 'scsb')
      end
      # TODO: unlink the tempfile here, update the tests to see what the mocked s3 has received
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
