# frozen_string_literal: true
require 'rails_helper'

RSpec.describe TMASGateCounts::FetchTMASCounts do
  include Dry::Monads[:result]
  it 'retrieves the TMAS Gate Counts' do
    client = TMASGateCounts::TMASClient.new(api_key: 'MY_KEY', wait_for_rate_limit: ->() {})
    april_first_mock = stub_request(
        :get,
        'https://www.smssoftware.net/tms/manTrafExp?fromDate=04/01/2026&toDate=04/01/2026&interval=60&hours=0&reqType=td&apiKey=MY_KEY&locationId=mend0000'
      )
                       .to_return(status: 200, body: 'XML 1')
    april_second_mock = stub_request(
        :get,
        'https://www.smssoftware.net/tms/manTrafExp?fromDate=04/02/2026&toDate=04/02/2026&interval=60&hours=0&reqType=td&apiKey=MY_KEY&locationId=mend0000'
      )
                        .to_return(status: 200, body: 'XML 2')
    results = described_class
              .new(client:)
              .call(first: Date.parse('2026-04-01'), last: Date.parse('2026-04-02'), locations: ['mend0000'])

    expect(april_first_mock).to have_been_requested
    expect(april_second_mock).to have_been_requested

    expect(results).to eq(Success(['XML 1', 'XML 2']))
  end

  it 'short-circuits and returns Failure if request does not go through' do
    client = TMASGateCounts::TMASClient.new(api_key: 'MY_KEY', wait_for_rate_limit: ->() {})
    april_first_mock = stub_request(
        :get,
        'https://www.smssoftware.net/tms/manTrafExp?fromDate=04/01/2026&toDate=04/01/2026&interval=60&hours=0&reqType=td&apiKey=MY_KEY&locationId=mend0000'
      ).to_return(status: 500)
    results = described_class
              .new(client:)
              .call(first: Date.parse('2026-04-01'), last: Date.parse('2026-04-02'), locations: ['mend0000'])

    expect(april_first_mock).to have_been_requested

    expect(results).to eq(Failure('Got response 500 from the TMAS API'))
  end
end
