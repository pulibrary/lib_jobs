# frozen_string_literal: true

# Gather data from OIT's API store about people in the university
#
class OitPersonFeed
  attr_reader :base_url, :access_token, :path

  # @param base_url     [String] The url of the OIT API Store
  # @param path         [String] The path to the person feed within the api store.  (should start with /)
  # @param access_token [AccessToken] A class to give us access to the access token.  These are short lived so they are refreshed with each call
  def initialize(base_url: ENV['OIT_BASE_URL'], path: ENV['OIT_PERSON_FEED_URL'],
                 access_token: AccessToken.new(client_id: ENV["OIT_CLIENT_KEY"], client_secret: ENV["OIT_CLIENT_SECRET"], token_host: URI.parse(ENV['OIT_BASE_URL']).host))
    @base_url = base_url
    @path = path
    @access_token = access_token
  end

  # get json data from OIT
  #
  # @param begin_date   [String] starting date to look for changes format yyyy-mm-dd ('2020-01-01')
  # @param end_date     [String] ending date to look for changes format yyyy-mm-dd ('2020-01-01')
  # @param enabled_flag [String] ( 'E' enabled or 'I' inactive )
  # @returns [Hash]
  def get_json(begin_date:, end_date:, enabled_flag: 'E')
    uri = api_uri(begin_date: begin_date, end_date: end_date, enabled_flag: enabled_flag)
    request = Net::HTTP::Get.new(uri)
    request['Content-Type'] = 'application/json'
    request['Accept'] = 'application/json'
    request['Authorization'] = "Bearer #{access_token.fetch}"
    result = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end
    if result.instance_of?(Net::HTTPOK)
      JSON.parse(result.body)
    else
      Rails.logger.error("Unable to get person data with parameters #{params}.  Error: #{result.message}")
      {}
    end
  end

  private

  def api_uri(begin_date:, end_date:, enabled_flag:)
    params = { ei_flag: enabled_flag, begin_date: begin_date, end_date: end_date }
    uri = URI.parse(base_url)
    uri.path = path
    uri.query = URI.encode_www_form(params)
    uri
  end
end
