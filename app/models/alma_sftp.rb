# frozen_string_literal: true
class AlmaSftp
  attr_reader :ftp_host, :ftp_username, :ftp_password

  def initialize(ftp_host: Rails.application.config.alma_ftp.host,
                 ftp_username: Rails.application.config.alma_ftp.username,
                 ftp_password: Rails.application.config.alma_ftp.password)
    @ftp_host = ftp_host
    @ftp_username = ftp_username
    @ftp_password = ftp_password
  end

  def start
    retries ||= 0
    Net::SFTP.start(ftp_host, ftp_username, { password: ftp_password }) do |sftp|
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
