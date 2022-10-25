# frozen_string_literal: true

require 'net/http/post/multipart'

module AlmaPodRecords
  class AlmaPodSender
    def initialize(filename:, access_token: ENV['POD_ACCESS_TOKEN'], compressed: false)
      @filename = filename
      @access_token = access_token
      @compressed = compressed
    end

    def send_to_pod
      uri = URI('https://pod.stanford.edu/organizations/princeton/uploads')
      response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
        request = Net::HTTP::Post::Multipart.new(uri.path, parameters)
        request['Authorization'] = "Bearer #{@access_token}"
        request['Accept'] = 'application/json'
        http.request request
      end
      log_response response
      response.is_a? Net::HTTPSuccess
    end

    private

    def parameters
      {
        'upload[name]': @filename,
        'upload[files][]': UploadIO.new(File.new(@filename), 'application/marcxml+xml'),
        'stream': stream
      }
    end

    def stream
      if @compressed
        LibJobs.config[:pod_test_stream]
        # 'princeton-test-set'
      else
        LibJobs.config[:pod_default_stream]
        # 'production'
      end
    end

    def log_response(response)
      if response.is_a? Net::HTTPSuccess
        Rails.logger.info "Uploaded #{@filename} to POD: #{JSON.parse(response.body)['url']}"
      else
        Rails.logger.error "Could not post records to POD: #{response.body}"
      end
    end
  end
end
