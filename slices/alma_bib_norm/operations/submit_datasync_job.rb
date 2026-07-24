# frozen_string_literal: true
module AlmaBibNorm
  module Operations
    # Submit a Datasync job using the Alma API
    class SubmitDatasyncJob < Dry::Operation
      include Deps['settings']
      def call
        step post_request
      end

        private

      def post_request
        response = connection.post do |req|
          req.url "almaws/v1/conf/jobs/#{job_id}"
          req.headers['Content-Type'] = 'application/xml'
          req.headers['Accept'] = 'application/xml'
          req.params['apikey'] = settings.alma_config_api_key
          req.params['op'] = 'run'
          req.body = request_body
        end
        if response.status == 200
          Success(response)
        else
          Failure(response)
        end
      end

      def connection
        Faraday.new(url:) do |faraday|
          faraday.request :url_encoded
          faraday.response  :logger
          faraday.adapter   Faraday.default_adapter
        end
      end

      def job_id = 'M7407373650006421'
      def norm_rule_name = 'task_189_droolesFileKey'
      def norm_rule_value = 'Datasync xref norm'
      def distribution_name = 'task_189_distribution'
      def set_id = '23381130100006421'
      def job_value = 'PUL-BIBNorm - via API - Unprocessed Datasync 914 fields'
      def url = settings.alma_region

      # rubocop:disable Metrics/MethodLength
      def request_body
        Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
          xml.job do
            xml.parameters do
              xml.parameter do
                xml.name norm_rule_name
                xml.value norm_rule_value
              end
              xml.parameter do
                xml.name distribution_name
                xml.value 'true'
              end
              xml.parameter do
                xml.name 'set_id'
                xml.value set_id
              end
              xml.parameter do
                xml.name 'job_name'
                xml.value job_value
              end
            end
          end
        end.to_xml
      end
      # rubocop:enable Metrics/MethodLength
    end
  end
end
