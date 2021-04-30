# frozen_string_literal: true
require 'jwt'

class User < ApplicationRecord
  validates :email, presence: true
  has_many :batches, class_name: 'AbsoluteId::Batch', foreign_key: 'user_id'
  has_many :sessions, class_name: 'AbsoluteId::Session', foreign_key: 'user_id'

  after_validation do
    if token.nil?
      self.token = JWT.encode(digest, self.class.hmac_secret, 'HS256')
    else
      # Validate the token
      raise ActionController::InvalidAuthenticityToken unless token_valid?
    end
  end

  def self.hmac_secret
    LibJobs.config[:hmac_secret]
  end

  def self.institutional_email_domain
    "princeton.edu"
  end

  def self.from_omniauth(access_token)
    net_id = access_token.uid

    email = if net_id.include?("@")
              net_id
            else
              "#{net_id}@#{institutional_email_domain}"
            end

    User.where(email: email).first_or_create
  end

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :omniauthable, omniauth_providers: [:cas]

  def digest
    Digest::MD5.hexdigest(email)
  end

  def decoded_token
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
