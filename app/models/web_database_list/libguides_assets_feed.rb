# frozen_string_literal: true
class WebDatabaseList::LibguidesAssetsFeed
  def initialize(access_token: nil)
    @access_token = access_token ||
                    AccessToken.new(client_id: LibJobs.config[:libguides_client_id],
                                    client_secret: LibJobs.config[:libguides_client_secret],
                                    token_host: "lgapi-us.libapps.com",
                                    token_path: "/1.2/oauth/token")
  end

  def authorization_header
    "Authorization: Bearer #{@access_token.fetch}"
  end
end
