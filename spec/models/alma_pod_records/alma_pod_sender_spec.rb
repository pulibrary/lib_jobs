# frozen_string_literal: true
require 'rails_helper'

RSpec.describe AlmaPodRecords::AlmaPodSender, type: :model do
  let(:sender) { described_class.new(filename: file_fixture('marcxml_no_namespaces.xml').to_s, access_token: token) }
  let(:token) { 'GOOD_TOKEN' }
  let(:response_body) do
    '{"id":123,"name":"file.xml","url":"https://pod.stanford.edu/organizations/princeton/uploads/123.json"}'
  end
  let(:response_status) { 201 }

  before do
    stub_request(:post, "https://pod.stanford.edu/organizations/princeton/uploads")
      .with(headers: { 'Authorization' => "Bearer #{token}" })
      .to_return(status: response_status, body: response_body, headers: {})
  end

  context 'valid token' do
    it 'returns true if successful' do
      expect(sender.send_to_pod).to be true
    end
  end

  context 'invalid token' do
    let(:token) { 'BAD_TOKEN' }
    let(:response_body) { '' }
    let(:response_status) { 302 }

    it 'logs an error and returns false on a failed authentication' do
      allow(Rails.logger).to receive(:error).at_least(:once)
      expect(sender.send_to_pod).to be false
      expect(Rails.logger).to have_received(:error).once
    end
  end

  context 'with a compressed file' do
    let(:sender) { described_class.new(filename: file_fixture('marcxml_no_namespaces.xml').to_s, access_token: token) }

    it 'includes the test stream' do
      params = sender.send(:parameters)
      expect(params.keys).to include(:'upload[files][]')
      expect(params[:'upload[files][]'].content_type).to eq("application/marcxml+xml")
      expect(params.keys).to include(:'upload[name]')
      expect(params.keys).to include(:stream)
      expect(params[:stream]).to eq('princeton-prod-0223')
    end
  end
end
