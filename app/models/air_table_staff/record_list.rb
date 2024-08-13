# frozen_string_literal: true
module AirTableStaff
  # This class is responsible for maintaining a list
  # of staff records taken from the Airtable API
  class RecordList
    def initialize
      @token = LibJobs.config[:airtable_token]
    end

    def base_url
      @base_url ||= begin
        base_id = 'appv7XA5FWS7DG9oe'
        table_id = 'tblM0iymGN5oqDUVm'
        fields_to_use = StaffDirectoryMapping.new.fields.map { |field| field[:airtable_field_id].to_s }
        query_hash = { "fields": fields_to_use, "returnFieldsByFieldId": "true" }
        URI::HTTPS.build(
          host: 'api.airtable.com',
          path: "/v0/#{base_id}/#{table_id}",
          query: query_hash.to_query
        )
      end
    end

    # The library staff list is split into several pages.
    # For each page (except the last), Airtable gives us an
    # offset, which is how we request the next page.
    def to_a(offset: nil)
      @as_array ||= begin
        json = get_json(offset:)
        json_records = json[:records].select do |record|
          record_present = record[:fields].present? && (record[:fields][:fldvENk2uiLDHmYSw] || record[:fields][:fldnKprqGraSvNTJK])
          Rails.logger.error("This record #{record[:fields]} is missing first and/or last name. It will not be included.") unless record_present
          record_present
        end
        records = json_records.map do |row|
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

    attr_reader :token

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
