# frozen_string_literal: true
class GobiSftp < Sftp
  def initialize(sftp_host: Rails.application.config.gobi_sftp.host,
                 sftp_username: Rails.application.config.gobi_sftp.username,
                 sftp_password: Rails.application.config.gobi_sftp.password)
    super
  end
end
