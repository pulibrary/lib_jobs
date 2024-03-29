# frozen_string_literal: true
require "rails_helper"

RSpec.describe AccessToken do
  let(:service) { described_class.new(client_id: "id", client_secret: "secret", token_host: 'example.com', scope: '/read-public') }
  let(:response_body) do
    <<~EOF
      {"access_token":"token","token_type":"bearer","refresh_token":"refreshtoken","expires_in":631138518,"scope":"/read-public","orcid":null}
    EOF
  end
  let(:request_body) do
    { "client_id" => "id", "client_secret" => "secret", "grant_type" => "client_credentials", "scope" => "/read-public" }
  end

  before do
    stub_request(:post, "https://example.com/token")
      .with(
        body: request_body,
        headers: {
          "Accept" => "application/json",
          "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
          "Content-Type" => "application/x-www-form-urlencoded",
          "Host" => "example.com",
          "User-Agent" => "Ruby"
        }
      ).to_return(status: 200, body: response_body, headers: {})
  end

  describe ".fetch" do
    it "fetches a new access token" do
      expect(service.fetch).to eq "token"
    end
  end
  describe "scope parameter" do
    let(:service) { described_class.new(client_id: "id", client_secret: "secret", token_host: 'example.com') }
    let(:request_body) do
      { "client_id" => "id", "client_secret" => "secret", "grant_type" => "client_credentials" }
    end

    it 'is optional' do
      expect(service.fetch).to eq "token"
    end
  end
end
