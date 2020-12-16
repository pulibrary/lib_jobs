# frozen_string_literal: true
require 'jwt'

class User < ApplicationRecord
  validates :email, presence: true

  after_validation do
    if token.nil?
      self.token = JWT.encode(digest, self.class.hmac_secret, 'HS256')
    else
      # Validate the token
      raise ActionController::InvalidAuthenticityToken unless token_valid?
    end
  end

  def self.ecdsa_key
    OpenSSL::PKey::EC.read(foo)
  end

  def self.ecdsa_public
    OpenSSL::PKey::EC.new(ecdsa_key)
  end

  def self.hmac_secret
    'secret'
  end

  def digest
    Digest::MD5.hexdigest(email)
  end

  def decoded_token
    # JWT.decode(token, self.class.ecdsa_public, true, { algorithm: 'ES256' })
    JWT.decode(token, self.class.hmac_secret, true, { algorithm: 'HS256' })
  rescue JWT::DecodeError => decode_error
    Rails.logger.warn("Failed to decode the JSON Web Token for the user #{email}: #{decode_error}")
    token
  end

  def token_valid?
    return false if token.nil?

    decoded_token != token
  end
end
