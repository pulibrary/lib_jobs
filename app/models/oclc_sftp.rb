# frozen_string_literal: true
class OclcSftp < Sftp
  def initialize(sftp_host: Rails.application.config.oclc_sftp.host,
                 sftp_username: Rails.application.config.oclc_sftp.username,
                 sftp_password: Rails.application.config.oclc_sftp.password)
    super
  end
end
