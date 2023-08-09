# frozen_string_literal: true
module AlmaSubmitCollection
  class PartnerS3
    attr_reader :client, :bucket_name

    def initialize
      @client = s3_client_connection
      @bucket_name = s3_bucket
    end

    def s3_bucket
      ENV['SCSB_S3_BUCKET_NAME'] || 'scsb-uat'
    end

    def s3_client_connection
      Aws::S3::Client.new(
        region: 'us-east-2',
        credentials: Aws::Credentials.new(
          scsb_s3_partner_access_key, scsb_s3_partner_secret_access_key
        )
      )
    end

    private

    def scsb_s3_partner_secret_access_key
      Rails.configuration.scsb_s3[:scsb_s3_partner_secret_access_key]
    end

    def scsb_s3_partner_access_key
      Rails.configuration.scsb_s3[:scsb_s3_partner_access_key]
    end
  end
end
