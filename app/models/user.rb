# frozen_string_literal: true
require 'jwt'

class User < ApplicationRecord
  validates :email, presence: true
  has_many :batches, class_name: 'AbsoluteId::Batch'
  has_many :sessions, class_name: 'AbsoluteId::Session'

  after_validation do
    if token.nil?
      self.token = JWT.encode(digest, self.class.hmac_secret, 'HS256')
    else
      # Validate the token
      raise ActionController::InvalidAuthenticityToken unless token_valid?
    end
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

  def self.hmac_secret
    'secret'
  end

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

  class FindingAidService
    @cache = {}

    def self.find_cached(key)
      @cache[key]
    end

    def self.cached?(key)
      @cache.key?(key)
    end

    # This needs to implemented
    def self.cache_expired?(_path)
      false
    end

    def find_repository(repository_id:)
      path = "repositories/#{repository_id}"
      return self.class.find_cached(path) if self.class.cached?(path) && self.class.cache_expired?(path)

      repository = authenticated.get(path)

      self.class.cache(path, repository)
    end

    def find_resource(resource_id:)
      path = "#{client.config.base_repo}/resources/#{resource_id}"
      return self.class.find_cached(path) if self.class.cached?(path) && self.class.cache_expired?(path)

      resource = authenticated.get(path)

      self.class.cache(path, resource)
    end

    def self.client_class
      ArchivesSpace::Client
    end

    def configuration
      Rails.configuration.archivesspace
    end

    def initialize(**configuration)
      @configuration = configuration || self.class.default_configuration.merge(configuration)
    end

    def client
      @authenticated || @client ||= client_class.new(@configuration)
    end

    def authenticated?
      @authenticated.present?
    end

    def authenticate
      @authenticated = client.login unless authenticated?
    end

    def base_repository=(value)
      @client.config.base_repo = "repositories/#{value}"
    end
  end

  # This is in place for testing
  def archivesspace_username
    nil
  end

  # This is in place for testing
  def archivesspace_password
    nil
  end

  def archivesspace_configuration
    output = {}

    output[:username] = archivesspace_username if archivesspace_username.present?
    output[:password] = archivesspace_password if archivesspace_password.present?

    output
  end

  def finding_aid_service
    @finding_aid_service ||= FindingAidService.new(**archivesspace_configuration)
  end
end
