# frozen_string_literal: true
class WebDatabaseList::LibguidesAssetsFeed
  def initialize(access_token: nil)
    @access_token = access_token ||
                    AccessToken.new(client_id: LibJobs.config[:libguides_client_id],
                                    client_secret: LibJobs.config[:libguides_client_secret],
                                    token_host: "lgapi-us.libapps.com",
                                    token_path: "/1.2/oauth/token")
  end

  def fetch
    uri = URI('https://lgapi-us.libapps.com/1.2/az?expand=subjects,friendly_url,az_props')
    req = Net::HTTP::Get.new(uri)
    req['Authorization'] = authorization_header

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(req)
    end
    JSON.parse response.body
  end

  private

  def authorization_header
    "Bearer #{@access_token.fetch}"
  end
end
