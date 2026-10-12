require 'rails_helper'

RSpec.describe Shared::Repos::NextDateToProcessRepo do
  describe '#next' do
    it 'tells you which day to process next' do
      repo = described_class.new
      repo.create job: 'MyNiceJob', next: '2015-01-01'
      expect(repo.next(job: 'MyNiceJob')).to eq Some(Date.parse('2015-01-01'))
    end
    it 'returns None if we do not have a next date' do
      repo = described_class.new
      expect(repo.next(job: 'MyNiceJob')).to eq None()
    end
  end
  describe '#set' do
    it 'can set the next date if there is an existing date' do
      repo = described_class.new
      repo.create job: 'MyNiceJob', next: '2015-01-01'
      repo.set job: 'MyNiceJob', next: '2030-01-01'
      expect(repo.next(job: 'MyNiceJob')).to eq Some(Date.parse('2030-01-01'))
    end

    it 'can set the next date if there is no existing date' do
      repo = described_class.new
      repo.set job: 'MyNiceJob', next: '2050-01-01'
      expect(repo.next(job: 'MyNiceJob')).to eq Some(Date.parse('2050-01-01'))
    end
  end
end
