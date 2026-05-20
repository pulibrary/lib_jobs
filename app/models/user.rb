# frozen_string_literal: true

class User < ApplicationRecord
  validates :email, presence: true
  encrypts :email, deterministic: true, downcase: true

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

    User.where(email:).first_or_create
  end

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :omniauthable, omniauth_providers: [:cas]

  def digest
    Digest::MD5.hexdigest(email)
  end

  def admin?
    uid = email.split('@').first
    netids.include?(uid) || Rails.env.development?
  end

  private

  def netids
    @netids ||= ENV['LIB_JOBS_ADMIN_NETIDS']&.split(" ") || ""
  end
end
