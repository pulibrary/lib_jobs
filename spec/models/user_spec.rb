# frozen_string_literal: true
require 'rails_helper'

RSpec.describe User, type: :model do
  subject(:user) { described_class.create(email:) }

  let(:email) { 'user@princeton.edu' }

  describe '.institutional_email_domain' do
    it 'accesses the domain for user e-mail addresses' do
      expect(described_class.institutional_email_domain).to eq('princeton.edu')
    end
  end

  describe '.from_omniauth' do
    let(:uid) { email }
    let(:access_token) do
      OpenStruct.new(
        {
          uid:
        }
      )
    end
    let(:persisted) do
      described_class.from_omniauth(access_token)
    end

    it 'creates a model using the uid attribute' do
      expect(persisted).to be_a(described_class)
      expect(persisted.email).to eq('user@princeton.edu')
    end

    context 'when the uid does not contain the e-mail domain' do
      let(:uid) { 'user' }
      it 'creates a model using the uid attribute with the domain appended' do
        expect(persisted).to be_a(described_class)
        expect(persisted.email).to eq('user@princeton.edu')
      end
    end
    context 'with an existing user' do
      it 'does not create a new user with the same email' do
        persisted
        expect do
          described_class.from_omniauth(access_token)
        end.not_to change(User, :count)
      end
    end
  end

  describe('#admin?') do
    it 'returns true if user is in the list of netids' do
      subject.instance_variable_set(:@netids, %w[user user2])
      expect(subject.admin?).to eq(true)
    end
    it 'returns false if user is not in the list of netids' do
      subject.instance_variable_set(:@netids, %w[user2 user3])
      expect(subject.admin?).to eq(false)
    end
  end
end
