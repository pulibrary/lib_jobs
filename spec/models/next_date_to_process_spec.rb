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
  it 'can set the next date if there is an existing date' do
    described_class.create job: :MyNiceJob, next: '2015-01-01'
    described_class.set job: :MyNiceJob, next: '2030-01-01'
    expect(described_class.next(:MyNiceJob)).to eq Some(Date.parse('2030-01-01'))
  end

  it 'can set the next date if there is no existing date' do
    described_class.set job: :MyNiceJob, next: '2050-01-01'
    expect(described_class.next(:MyNiceJob)).to eq Some(Date.parse('2050-01-01'))
  end
end
