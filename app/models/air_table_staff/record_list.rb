# frozen_string_literal: true
module AirTableStaff
  # This class is responsible for maintaining a list
  # of staff records taken from the Airtable API
  class RecordList
    def initialize
      @base_url = "https://api.airtable.com/v0/appv7XA5FWS7DG9oe/Synchronized%20Staff%20Directory%20View?view=Grid%20view"
      @token = LibJobs.config[:airtable_token]
    end

    # The library staff list is split into several pages.
    # For each page (except the last), Airtable gives us an
    # offset, which is how we request the next page.
    def to_a(offset: nil)
      @as_array ||= begin
        json = get_json(offset:)
        records = json[:records].map do |row|
          AirTableStaff::StaffDirectoryPerson.new(row[:fields])
        end
        offset = json[:offset]

        # If we have an offset, call this method recursively
        # (to fetch additional pages of data), until airtable
        # no longer gives us an offset
        records += to_a(offset:) if offset
        records
      end
    end

    private

    attr_reader :base_url, :token

    def get_json(offset: nil)
      JSON.parse(response(offset:).body, symbolize_names: true)
    end

    def response(offset: nil)
      url = url_with_optional_offset(offset:)
      request = Net::HTTP::Get.new(url)
      request["Authorization"] = "Bearer #{token}"
      Net::HTTP.start(url.hostname, url.port, { use_ssl: true }) do |http|
        http.request(request)
      end
    end

    def url_with_optional_offset(offset: nil)
      URI.parse(offset ? "#{base_url}&offset=#{offset}" : base_url)
    end
  end
end
