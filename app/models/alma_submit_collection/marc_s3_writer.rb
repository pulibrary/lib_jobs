# frozen_string_literal: true
module AlmaSubmitCollection
  # This class is responsible for accepting
  # MARC data and writing it to files in an
  # AWS S3 bucket
  class MarcS3Writer
    attr_reader :s3_partner, :client, :bucket

    def initialize(records_per_file: 10_000, file_type: 'std')
      @records_in_file = 0
      @records_per_file = records_per_file
      @file_type = file_type
      @s3_partner = AlmaSubmitCollection::PartnerS3.new
      @client = @s3_partner.client
      @bucket = @s3_partner.bucket_name
    end

    def write(record)
      marc_writer.write record
      @records_in_file += 1
    end

    def marc_writer
      if @marc_writer
        return @marc_writer unless full
        done
      end
      @current_file = Tempfile.new(filename_components)
      @marc_writer = MARC::XMLWriter.new(@current_file)
      @records_in_file = 0
      @marc_writer
    end

    def done
      return unless @marc_writer
      @marc_writer.close
      file_path = @current_file.path
      File.open(file_path) do |file_contents|
        compressed = StringIO.new
        compressor = Zlib::GzipWriter.new(compressed)
        # Compress the file contents 10 bytes at a time,
        # rather than reading the whole uncompressed file
        # contents into memory all at once
        while (chunk = file_contents.read(10))
          compressor.write chunk
        end
        compressor.close
        Rails.logger.debug('SubmitCollection: Writing file to SCSB S3')
        client.put_object(bucket:, body: compressed.string, key: "#{Rails.configuration.scsb_s3[:scsb_s3_updates]}/scsb_#{File.basename(file_path)}")
      end
      @current_file.unlink
    end

    private

    def filename_components
      components = ["scsb_submitcollection_#{@file_type}"]
      components << "#{Time.current.iso8601}.marcxml.gz"
      components
    end

    def full
      @records_in_file >= @records_per_file
    end
  end
end
