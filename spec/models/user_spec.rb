# frozen_string_literal: true
require 'rails_helper'

RSpec.describe User, type: :model do
  subject(:user) { described_class.create(email: email) }

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
          uid: uid
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
  end

  describe '#decoded_token' do
    it 'accesses the decoded JSON web token' do
      expect(user.decoded_token).to eq(
        [
          "3d494700a68028e04fc1c444f8cd1cad",
          {
            "alg" => "HS256"
          }
        ]
      )
    end

    context 'when the JSON Web Token cannot be decoded' do
      let(:logger) { instance_double(ActiveSupport::Logger) }

      before do
        allow(logger).to receive(:warn)
        allow(Rails).to receive(:logger).and_return(logger)
        allow(JWT).to receive(:decode).and_raise(JWT::DecodeError)
      end

      it 'logs a warning and returns the encoded JSON web token' do
        expect(user.decoded_token).to eq('eyJhbGciOiJIUzI1NiJ9.IjNkNDk0NzAwYTY4MDI4ZTA0ZmMxYzQ0NGY4Y2QxY2FkIg.T2mp-OpT2WiKrGHW6PN5VJm-NVqed8E2aTaoRkoNPD8')
        expect(logger).to have_received(:warn).with('Failed to decode the JSON Web Token for the user user@princeton.edu: JWT::DecodeError')
      end
    end
  end
end
