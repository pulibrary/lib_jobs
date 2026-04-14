# frozen_string_literal: true
require 'rails_helper'

RSpec.describe NextDateToProcess do
  include Dry::Monads[:maybe]
  it 'tells you which day to process next' do
    described_class.create job: :MyNiceJob, next: '2015-01-01'
    expect(described_class.next(:MyNiceJob)).to eq Some(Date.parse('2015-01-01'))
  end
  it 'returns None if we do not have a next date' do
    expect(described_class.next(:MyNiceJob)).to eq None()
  end
end
