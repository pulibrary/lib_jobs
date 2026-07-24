# frozen_string_literal: true

module AlmaBibNorm
  class AlmaBibNorm < LibJob
    include Dry::Monads[:result]
    include Deps['mailers.error_notification', 'operations.submit_datasync_job']

    private

    def handle(data_set:)
      data_set.report_time = Time.zone.now

      case submit_datasync_job.call
      in Success(Faraday::Response => response)
        data_set.status = true
      in Failure(Faraday::Response => response)
        data_set.status = false
        error_message = Nokogiri::XML(response.body).xpath("web_service_result//errorList//error//errorMessage").text
        data_set.data = "Job failed with response code: #{response.status}, and body: #{error_message}"
        error_notification.deliver(error_code: response.status, error_message:)
      end

      data_set
    end

    def category = 'PulBibNorm'
  end
end
