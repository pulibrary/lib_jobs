# frozen_string_literal: true
require 'rails_helper'

include Dry::Monads[:result]

RSpec.describe RecentJobStatus do
  it 'can register success' do
    described_class.register job: :MyNiceJob, status: Success(:great)
    result = described_class.find_by job: :MyNiceJob
    expect(result.status).to eq 'success'
  end
  it 'can register failure' do
    described_class.register job: :MyNiceJob, status: Failure(:oh_no)
    result = described_class.find_by job: :MyNiceJob
    expect(result.status).to eq 'failure'
  end
  it 'only keeps the most recent registration' do
    described_class.register job: :MyNiceJob, status: Failure(:oh_no)
    described_class.register job: :MyNiceJob, status: Success(:great)
    result = described_class.find_by job: :MyNiceJob
    expect(result.status).to eq 'success'
  end
  it 'does not register nonsense' do
    expect do
      described_class.register job: :MyNonsenseJob, status: 'I AM A BUNCH OF NONSENSE'
    end.to raise_error
  end
end
