# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AlmaFundAdjustment::Repos::PeoplesoftTransactionsRepo do
  subject(:repo) do
    described_class.new
  end

  describe '#create' do
    it 'adds created_at and updated_at timestamps on insert' do
      Timecop.freeze(DateTime.new(2040, 4, 1))
      transaction_id = '☕-Morning Budget | 咖啡 Shop | 03/13/2021'

      repo.create(transaction_id:)

      record = repo.peoplesoft_transactions.where(transaction_id:).first

      expect(record.transaction_id).to eq(transaction_id)
      expect(record.created_at).to eq '2040-04-01'
      expect(record.updated_at).to eq '2040-04-01'
      Timecop.return
    end

    it 'handles emoji, diacritics and other unicode edge cases' do
      repo.create(transaction_id: '🔥-Rush charge | naïve café | 12/31/2024')

      expect(repo.exists?(transaction_id: '🔥-Rush charge | naïve café | 12/31/2024')).to be(true)
    end
  end

  describe '#exists?' do
    it 'returns true when the transaction id has already been processed' do
      repo.create(transaction_id: '☕-Morning Budget | 咖啡 Shop | 03/13/2021')

      expect(repo.exists?(transaction_id: '☕-Morning Budget | 咖啡 Shop | 03/13/2021')).to be(true)
    end

    it 'returns false when the transaction id is unknown' do
      expect(repo.exists?(transaction_id: '123456-Online Entry | A Fund We have | 07/14/2021')).to be(false)
    end
  end
end
