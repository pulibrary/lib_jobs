# frozen_string_literal: true
class AlmaSftp
  attr_reader :ftp_host, :ftp_username, :ftp_password

  def initialize(ftp_host: Rails.application.config.alma_ftp.host, ftp_username: Rails.application.config.alma_ftp.username, ftp_password: Rails.application.config.alma_ftp.password)
    @ftp_host = ftp_host
    @ftp_username = ftp_username
    @ftp_password = ftp_password
  end

  def start
    Net::SFTP.start(ftp_host, ftp_username, { password: ftp_password }) do |sftp|
      yield(sftp)
    end
  end
end
