# frozen_string_literal: true
module AlmaSubmitCollection
  # This class is responsible for accepting
  # MARC data and writing it to files in an
  # AWS S3 bucket
  class MarcS3Writer
    def initialize(records_per_file: 10_000, file_type: 'std', s3_client: nil)
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
        @s3_client.put_object(bucket:, body: file_contents, key: "#{ENV['SCSB_S3_UPDATES']}/scsb_#{File.basename(file_path)}")
      end
      @current_file.unlink
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

    def bucket
      ENV['SCSB_S3_BUCKET_NAME'] || 'scsb-uat'
    end
  end
end
