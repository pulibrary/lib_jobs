# frozen_string_literal: true

module Shared
  # lifted from https://github.com/pulibrary/orcid-client
  # Tokens are live for an hour and should be regenerated often
  class AccessToken
    # Get a brand new token
    # @returns [String] access token
    def fetch(client_id:, client_secret:, token_host:, token_path: '/token', scope: nil)
      url = url_for(token_host:, token_path:)
      Net::HTTP.start(url.host, url.port, use_ssl: true) do |http|
        req = Net::HTTP::Post.new(url)
        req['Accept'] = 'application/json'
        data = {
          'client_id' => client_id,
          'client_secret' => client_secret,
          'grant_type' => 'client_credentials'
        }
        data['scope'] = scope if scope
        req.set_form_data(data)
        body = http.request(req).body
        JSON.parse(body)['access_token']
      end
    end

    private

    def url_for(token_host:, token_path:)
      URI::HTTPS.build(host: token_host, path: token_path)
    end
  end
end
