# frozen_string_literal: true
class AlmaSftp < Sftp
  def initialize(sftp_host: Rails.application.config.alma_sftp.host,
                 sftp_username: Rails.application.config.alma_sftp.username,
                 sftp_password: Rails.application.config.alma_sftp.password)
    super
  end
end
