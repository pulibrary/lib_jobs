# frozen_string_literal: true
require 'rails_helper'

RSpec.describe AlmaPodRecords::AlmaPodSender, type: :model do
  it 'returns true if successful' do
    stub_request(:post, "https://pod.stanford.edu/organizations/princeton/uploads")
      .with(headers: { 'Authorization' => 'Bearer GOOD_TOKEN' })
      .to_return(status: 201, body: '{"id":123,"name":"file.xml","url":"https://pod.stanford.edu/organizations/princeton/uploads/123.json"}', headers: {})

    sender = described_class.new(filename: file_fixture('marcxml_no_namespaces.xml').to_s, access_token: 'GOOD_TOKEN')
    expect(sender.send).to be true
  end

  it 'logs an error and returns false on a failed authentication' do
    allow(Rails.logger).to receive(:error).at_least(:once)
    stub_request(:post, "https://pod.stanford.edu/organizations/princeton/uploads")
      .with(headers: { 'Authorization' => 'Bearer BAD_TOKEN' })
      .to_return(status: 302, body: "", headers: {})

    sender = described_class.new(filename: file_fixture('marcxml_no_namespaces.xml').to_s, access_token: 'BAD_TOKEN')
    expect(sender.send).to be false
    expect(Rails.logger).to have_received(:error).once
  end
end
