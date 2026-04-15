# frozen_string_literal: true
require 'rails_helper'

def stub_tmas_airtable_api(method: :post)
  stub_request(
      method,
      'https://api.airtable.com/v0/appAqHrmsuH7VsZOB/tblLkWS3cZh8YqlgN'
    ).with(
      body: '{}',
      headers: { 'Authorization' => 'Bearer my_token', 'Content-Type' => 'application/json' }
    )
end

RSpec.describe TMASGateCounts::AirtableClient do
  it 'can make a request' do
    client = described_class.new(env: { 'PEOPLE_COUNTER_AIRTABLE_TOKEN' => 'my_token' })
    http_request = stub_tmas_airtable_api

    expect(client.call(json: '{}')).to be_success

    expect(http_request).to have_been_requested
  end

  it 'can make a delete request' do
    client = described_class.new(env: { 'PEOPLE_COUNTER_AIRTABLE_TOKEN' => 'my_token' })
    http_request = stub_tmas_airtable_api(method: :delete)

    expect(client.call(json: '{}', request_class: Net::HTTP::Delete)).to be_success

    expect(http_request).to have_been_requested
  end

  it 'returns Failure if airtable API returns 422' do
    client = described_class.new(env: { 'PEOPLE_COUNTER_AIRTABLE_TOKEN' => 'my_token' })
    http_request = stub_tmas_airtable_api.to_return(status: 422)

    expect(client.call(json: '{}')).to be_failure

    expect(http_request).to have_been_requested
  end
end
