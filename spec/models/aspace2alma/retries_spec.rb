# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Aspace2alma::Retries do
  let(:job_class) do
    Class.new do
      include Aspace2alma::Retries

      def fetch(errors, &)
        with_retries(errors, 'fetching something', &)
      end
    end
  end
  let(:job) { job_class.new }

  before do
    allow(job).to receive(:sleep)
    allow(Rails.logger).to receive(:warn)
  end

  it 'recovers after a transient failure' do
    calls = 0
    result = job.fetch(described_class::ASPACE_ERRORS) do
      calls += 1
      raise Net::ReadTimeout if calls == 1

      'record'
    end

    expect(result).to eq('record')
    expect(job).to have_received(:sleep).with(1).once
    expect(Rails.logger).to have_received(:warn).with(/Net::ReadTimeout.*while fetching something, retry 1 of 3/)
  end

  it 'retries after 1, 2 and 3 seconds, then raises the error again' do
    calls = 0
    expect do
      job.fetch(described_class::NETWORK_ERRORS) do
        calls += 1
        raise Errno::ECONNRESET
      end
    end.to raise_error(Errno::ECONNRESET)

    expect(calls).to eq(described_class::RETRY_ATTEMPTS + 1)
    expect(job).to have_received(:sleep).with(1).ordered
    expect(job).to have_received(:sleep).with(2).ordered
    expect(job).to have_received(:sleep).with(3).ordered
  end

  it 'only retries network errors' do
    calls = 0
    expect do
      job.fetch(described_class::NETWORK_ERRORS) do
        calls += 1
        raise ArgumentError
      end
    end.to raise_error(ArgumentError)

    expect(calls).to eq(1)
  end
end
