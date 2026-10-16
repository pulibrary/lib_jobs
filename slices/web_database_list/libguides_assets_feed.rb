# frozen_string_literal: true

module WebDatabaseList
  # This class represents the information we can obtain about databases from Libguides
  class LibguidesAssetsFeed
    include Deps['shared.access_token', 'settings']

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
      "Bearer #{access_token.fetch(client_id: settings.libguides_client_id,
                                   client_secret: settings.libguides_client_secret,
                                   token_host: 'lgapi-us.libapps.com',
                                   token_path: '/1.2/oauth/token')}"
    end
  end
end
