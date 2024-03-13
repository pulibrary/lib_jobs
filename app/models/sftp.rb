# frozen_string_literal: true
class Sftp
  attr_reader :sftp_host, :sftp_username
  def initialize(sftp_host:, sftp_username:, sftp_password:)
    @sftp_host = sftp_host
    @sftp_username = sftp_username
    @sftp_password = sftp_password
  end

  def start
    retries ||= 0
    Net::SFTP.start(sftp_host, sftp_username, { password: @sftp_password }) do |sftp|
      yield(sftp)
    end
  rescue Net::SSH::Disconnect => error
    while (retries += 1) <= 3
      Rails.logger.warn("Encountered #{error.class}: '#{error.message}' when connecting at #{Time.now.utc}, retrying in #{retries} second(s)...")
      sleep(retries)
      retry
    end
    Rails.logger.error("Encountered #{error.class}: '#{error.message}' at #{Time.now.utc}, unsuccessful in connecting after #{retries} retries")
  end
end
