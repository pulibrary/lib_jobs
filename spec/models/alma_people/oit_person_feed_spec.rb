# frozen_string_literal: true
require "rails_helper"

RSpec.describe AlmaPeople::OitPersonFeed do
  subject(:feed) { described_class.new(base_url: 'https://example.com', path: '/person_feed', access_token: token) }
  let(:token) { instance_double("AccessToken") }

  let(:body) { '{"records":[ ]}' }

  describe "get" do
    before do
      stub_request(:get, "https://example.com/person_feed/E/2020-01-01/2020-02-01")
        .with(
        headers: {
          'Accept' => 'application/json',
          'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'Authorization' => 'Bearer secret_token',
          'Content-Type' => 'application/json',
          'Host' => 'example.com',
          'User-Agent' => 'Ruby'
        }
      )
        .to_return(status: 200, body:, headers: {})
    end
    it "gets an new token and then gets data from the api" do
      allow(token).to receive(:fetch).and_return('secret_token')
      expect(feed.get_json(begin_date: '2020-01-01', end_date: '2020-02-01').count).to eq(0)
      expect(token).to have_received(:fetch)
    end

    context "with people in the response" do
      let(:body) do
        "{\"records\":[{  \"PATRON_EXPIRATION_DATE\": \"2022-10-31\",\n     \"PATRON_PURGE_DATE\": \"2021-10-31\",\n     \"ELIGIBLE_INELIGIBLE\": \"E\",\n"\
        "    \"INSERT_UPDATE_DATETIME\": \"2020-12-03T08:21:02.000-05:00\",\n     \"PVSTATCATEGORY\": \"EM\",\n     \"ADDRESS_END_DATE\": \"2021-10-31\",\n"\
        "     \"PVPATRONGROUP\": \"P\",\n     \"DEPTID\": \"9999\",\n     \"DEPT_DESCR\": \"PRINCO\",\n     \"EMPLID\": \"999999999\",\n"\
        "     \"PRF_OR_PRI_FIRST_NAM\": \"Sally\",\n     \"PRF_OR_PRI_LAST_NAME\": \"Smith\",\n     \"PRF_OR_PRI_MIDDLE_NAME\": \"Doe\",\n"\
        "     \"PU_BARCODE\": \"999999999999\",\n     \"CAMPUS_ID\": \"sds99\",\n     \"CAMP_COUNTRY\": \"USA\",\n     \"CAMP_ADDRESS1\": \"PRINCO\",\n"\
        "     \"CAMP_ADDRESS2\": \"99 Princeton Street, Suite 999\",\n     \"CAMP_ADDRESS3\": null,\n     \"CAMP_ADDRESS4\": null,\n     \"CAMP_CITY\": \"Princeton\",\n"\
        "     \"CAMP_COUNTY\": null,\n     \"CAMP_STATE\": \"NJ\",\n     \"CAMP_POSTAL\": \"08544\",\n     \"CAMP_COUNTRY_DESCR\": \"United States\",\n     \"CAMP_STATE_DESCR\": \"New Jersey\",\n"\
        "     \"HOME_COUNTRY\": \"USA\",\n     \"HOME_ADDRESS1\": \"99 WhereILive Street\",\n     \"HOME_ADDRESS2\": null,\n     \"HOME_ADDRESS3\": null,\n     \"HOME_ADDRESS4\": null,\n"\
        "     \"HOME_CITY\": \"Princeton\",\n     \"HOME_COUNTY\": \"Mercer\",\n     \"HOME_STATE\": \"NJ\",\n     \"HOME_POSTAL\": \"08540-4054\",\n"\
        "     \"HOME_COUNTRY_DESCR\": \"United States\",\n     \"HOME_STATE_DESCR\": \"New Jersey\",\n     \"HOME_EMAIL\": \"sallysmith@gmail.com\",\n     \"HOME_PHONE\": null,\n"\
        "     \"CAMP_EMAIL\": \"sds99@princeton.edu\",\n     \"PERM_COUNTRY\": \"USA\",\n     \"PERM_ADDRESS1\": \"99 WhereILive Circle\",\n"\
        "     \"PERM_ADDRESS2\": null,\n     \"PERM_ADDRESS3\": null,\n     \"PERM_ADDRESS4\": null,\n     \"PERM_CITY\": \"Bradenton\",\n     \"PERM_COUNTY\": \"Manatee\",\n"\
        "     \"PERM_STATE\": \"FL\",\n     \"PERM_POSTAL\": \"34209\",\n     \"PERM_COUNTRY_DESCR\": \"United States\",\n     \"PERM_STATE_DESCR\": \"Florida\",\n"\
        "     \"PERM_PHONE\": \"123/456-7890\",\n     \"DORM_COUNTRY\": null,\n     \"DORM_ADDRESS1\": null,\n     \"DORM_ADDRESS2\": null,\n     \"DORM_ADDRESS3\": null,\n"\
        "     \"DORM_ADDRESS4\": null,\n     \"DORM_CITY\": null,\n     \"DORM_COUNTY\": null,\n     \"DORM_STATE\": null,\n     \"DORM_POSTAL\": null,\n"\
        "     \"DORM_COUNTRY_DESCR\": null,\n     \"DORM_STATE_DESCR\": null,\n     \"EMAIL_ADDRESS_END_DATE\": \"2022-10-30T20:00:00.000-04:00\"\n   }]}"
      end

      it "gets json data from the api" do
        allow(token).to receive(:fetch).and_return('secret_token')
        data = feed.get_json(begin_date: '2020-01-01', end_date: '2020-02-01')
        expect(data.count).to eq(1)
        expect(data[0]["EMPLID"]).to eq("999999999")
      end
    end

    context "without a enabled flag" do
      before do
        stub_request(:get, "https://example.com/person_feed/2020-01-01/2020-02-01")
          .with(
          headers: {
            'Accept' => 'application/json',
            'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
            'Authorization' => 'Bearer secret_token',
            'Content-Type' => 'application/json',
            'Host' => 'example.com',
            'User-Agent' => 'Ruby'
          }
        )
          .to_return(status: 200, body: body2, headers: {})
      end

      let(:body2) do
        "{\"records\":[{ \"EMPLID\": \"99998888\"\n   }]}"
      end

      it "gets an new token and then gets data from the api" do
        allow(token).to receive(:fetch).and_return('secret_token')
        data = feed.get_json(begin_date: '2020-01-01', end_date: '2020-02-01', enabled_flag: nil)
        expect(data.count).to eq(1)
        expect(data[0]["EMPLID"]).to eq("99998888")
        expect(token).to have_received(:fetch)
      end
    end

    context "without a begin end date" do
      before do
        stub_request(:get, "https://example.com/person_feed/E")
          .with(
          headers: {
            'Accept' => 'application/json',
            'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
            'Authorization' => 'Bearer secret_token',
            'Content-Type' => 'application/json',
            'Host' => 'example.com',
            'User-Agent' => 'Ruby'
          }
        )
          .to_return(status: 200, body: body3, headers: {})
      end

      let(:body3) do
        "{\"records\":[{ \"EMPLID\": \"11112222\"\n   }]}"
      end

      it "gets an new token and then gets data from the api" do
        allow(token).to receive(:fetch).and_return('secret_token')
        data = feed.get_json(begin_date: nil, end_date: nil)
        expect(data.count).to eq(1)
        expect(data[0]["EMPLID"]).to eq("11112222")
        expect(token).to have_received(:fetch)
      end
    end

    context "without a begin end date or enabled flag" do
      before do
        stub_request(:get, "https://example.com/person_feed")
          .with(
          headers: {
            'Accept' => 'application/json',
            'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
            'Authorization' => 'Bearer secret_token',
            'Content-Type' => 'application/json',
            'Host' => 'example.com',
            'User-Agent' => 'Ruby'
          }
        )
          .to_return(status: 200, body: body3, headers: {})
      end

      let(:body3) do
        "{\"records\":[{ \"EMPLID\": \"55556666\"\n   }]}"
      end

      it "gets an new token and then gets data from the api" do
        allow(token).to receive(:fetch).and_return('secret_token')
        data = feed.get_json(begin_date: nil, end_date: nil, enabled_flag: nil)
        expect(data.count).to eq(1)
        expect(data[0]["EMPLID"]).to eq("55556666")
        expect(token).to have_received(:fetch)
      end
    end
  end
end
