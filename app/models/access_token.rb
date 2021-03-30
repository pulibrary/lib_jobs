# frozen_string_literal: true

# lifted from https://github.com/pulibrary/orcid-client
# Tokens are live for an hour and should be regenerated often
class AccessToken
  attr_reader :client_id, :client_secret, :token_host, :token_path
  def initialize(client_id:, client_secret:, token_host:, token_path: "/token")
    @client_id = client_id
    @client_secret = client_secret
    @token_host = token_host
    @token_path = token_path
  end

  # Get a brand new token
  # @returns [String] access token
  def fetch
    Net::HTTP.start(url.host, url.port, use_ssl: true) do |http|
      req = Net::HTTP::Post.new(url)
      req["Accept"] = "application/json"
      data = {
        "client_id" => client_id,
        "client_secret" => client_secret,
        "grant_type" => "client_credentials",
        "scope" => "/read-public"
      }
      req.set_form_data(data)
      body = http.request(req).body
      JSON.parse(body)["access_token"]
    end
  end

  private

  def url
    @url ||= URI::HTTPS.build(host: token_host, path: token_path)
  end
end
