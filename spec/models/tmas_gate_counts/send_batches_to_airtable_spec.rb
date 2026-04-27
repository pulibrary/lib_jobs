# frozen_string_literal: true
require 'rails_helper'

RSpec.describe TMASGateCounts::SendBatchesToAirtable do
  it 'can send batches to airtable' do
    batches = ["batch 1", "batch 2"]
    client = instance_double(TMASGateCounts::AirtableClient, call: Success('{"records":[{"id": "123"}]}'))

    described_class.new(client).call(batches)

    expect(client).to have_received(:call).with(json: "batch 1")
    expect(client).to have_received(:call).with(json: "batch 2")
  end

  it 'reports the ids from Airtable' do
    batches = ["batch 1", "batch 2"]
    client = instance_double(TMASGateCounts::AirtableClient)
    allow(client).to receive(:call).and_return(
        Success('{"records":[{"id": "id 1"}]}'),
        Success('{"records":[{"id": "id 2"}]}')
      )

    result = described_class.new(client).call(batches)

    expect(result).to eq(Success(["id 1", "id 2"]))
  end

  it 'rolls back and stops on failure' do
    batches = ["batch 1", "batch 2", 'batch 3']
    client = instance_double(TMASGateCounts::AirtableClient)
    allow(client).to receive(:call).with(json: 'batch 1').and_return(Success('{"records":[{"id": "id1"}]}'))
    allow(client).to receive(:call).with(json: 'batch 2').and_return(Failure())
    allow(client).to receive(:call).with(request_class: Net::HTTP::Delete, uri_builder: kind_of(Proc))

    result = described_class.new(client).call(batches)

    # We send batch 1 and 2 to the client, but not batch 3 since a previous batch failed
    expect(client).to have_received(:call).with(json: 'batch 1')
    expect(client).to have_received(:call).with(json: 'batch 2')

    # We roll back the ids that have previously succeeded
    expect(client).to have_received(:call).with(
        request_class: Net::HTTP::Delete,
        uri_builder: valid_delete_uri_builder
      )

    # We return Failure
    expect(result).to be_failure
  end

  def valid_delete_uri_builder
    satisfy do |builder|
      builder.call('base', 'table') == URI.parse('https://api.airtable.com/v0/base/table?records[]=id1')
    end
  end
end
