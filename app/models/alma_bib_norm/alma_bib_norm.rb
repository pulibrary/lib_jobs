# frozen_string_literal: true

module AlmaBibNorm
  class AlmaBibNorm < LibJob

    def initialize()
      super(category: "PulBibNorm")
      @url = LibJobs.config[:alma_region]
      @api_key =  LibJobs.config[:alma_api_key]
      @job_id = 'M7407373650006421'
      @norm_rule_name = 'task_189_droolesFileKey'
      @norm_rule_value = 'Datasync xref norm'
      @distribution_name = 'task_189_distribution'
      @set_id = '23381130100006421'
      @job_value = 'PUL-BIBNorm - via API - Unprocessed Datasync 914 fields'
    end

    def handle(data_set:)
      data_set.report_time = Time.zone.now

      response = connection.post do |req|
        req.url "almaws/v1/conf/jobs/#{@job_id}"
        req.headers['Content-Type'] = 'application/xml'
        req.headers['Accept'] = 'application/xml'
        req.params['apikey'] = @api_key
        req.params['op'] = 'run'
        req.body = request_body
      end

      if response.status == 200
        data_set.status = true
      else
        data_set.status = false
        error_message = Nokogiri::XML(response.body).xpath("web_service_result//errorList//error//errorMessage").text
        data_set.data = "Job failed with response code: #{response.status}, and body: #{error_message}"
        AlmaBibNormMailer.error_notification(response.status, error_message)
      end

      data_set
    end

    private

    def connection
      Faraday.new(url: @url) do |faraday|
        faraday.request   :url_encoded
        faraday.response  :logger
        faraday.adapter   Faraday.default_adapter
      end
    end

    def request_body()
      Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
        xml.job {
          xml.parameters {
            xml.parameter {
              xml.name @norm_rule_name
              xml.value @norm_rule_value
            }
            xml.parameter {
              xml.name @distribution_name
              xml.value 'true'
            }
            xml.parameter {
              xml.name 'set_id'
              xml.value @set_id
            }
            xml.parameter {
              xml.name 'job_name'
              xml.value @job_value
            }
          }
        }
      end.to_xml
    end
  end
end
