# frozen_string_literal: true
require 'rails_helper'

def mock_alma_api_environment_variables
  allow(ENV).to receive(:fetch) do |var|
    {
      'ALMA_CONFIG_API_KEY' => 'my-key',
      'ALMA_REGION' => 'https://api-na.hosted.exlibrisgroup.com',
      'ALMA_SC_BARCODES_SET' => '43977868370006421'
    }[var]
  end
end

def mock_page1
  stub_request(:get, 'https://api-na.hosted.exlibrisgroup.com/almaws/v1/conf/sets/43977868370006421/members')
    .with(query: { 'limit' => 100, 'offset' => 0, 'apikey' => 'my-key' })
    .to_return_json(body: { member: [
                      { id: '23480173760006421', description: 'barcode1a',
                        link: 'https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs/9940026013506421/holdings/22480173830006421/items/23480173760006421' },
                      { id: '23480173770006421', description: 'barcode1b', link: 'https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs/9940026013506421/holdings/22480173830006421/items/23480173770006421' }
                    ], total_record_count: 280 })
end

def mock_page2
  stub_request(:get, 'https://api-na.hosted.exlibrisgroup.com/almaws/v1/conf/sets/43977868370006421/members')
    .with(query: { 'limit' => 100, 'offset' => 100, 'apikey' => 'my-key' })
    .to_return_json(body: { member: [
                      { id: '23480184420006421', description: 'barcode2a', link: 'https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs/9968719913506421/holdings/22480184430006421/items/23480184420006421' }
                    ], total_record_count: 280 })
end

def mock_page3
  stub_request(:get, 'https://api-na.hosted.exlibrisgroup.com/almaws/v1/conf/sets/43977868370006421/members')
    .with(query: { 'limit' => 100, 'offset' => 200, 'apikey' => 'my-key' })
    .to_return_json(body: { member: [
                      { id: '23480192370006421', description: 'barcode3a', link: 'https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs/9940026083506421/holdings/22480192420006421/items/23480192370006421' }
                    ], total_record_count: 280 })
end

def mock_alma_api_responses
  [mock_page1, mock_page2, mock_page3]
end

RSpec.describe Aspace2alma::AlmaDuplicateBarcodeCheck do
  it 'makes requests to alma' do
    mock_alma_api_environment_variables
    page1, page2, page3 = mock_alma_api_responses

    described_class.new.duplicate? 'barcode99999'

    # We request this page twice: once to get the total count of barcodes,
    # and once to get the actual barcode data
    assert_requested page1, times: 2
    assert_requested page2
    assert_requested page3
  end

  it 'raises an error if we are missing the api key' do
    expect { described_class.new.duplicate? 'barcode99999' }.to raise_error 'Missing the ALMA_CONFIG_API_KEY environment variable; please set it to a valid api key with config read permissions'
  end

  it 'can use the API to determine if a barcode is a duplicate' do
    mock_alma_api_environment_variables
    mock_alma_api_responses
    duplicate_checker = described_class.new

    expect(duplicate_checker.duplicate?('barcode1a')).to be true
    expect(duplicate_checker.duplicate?('barcode1b')).to be true
    expect(duplicate_checker.duplicate?('barcode2a')).to be true
    expect(duplicate_checker.duplicate?('barcode3a')).to be true
    expect(duplicate_checker.duplicate?('barcode99999')).to be false
  end
end
