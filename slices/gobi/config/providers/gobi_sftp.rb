# frozen_string_literal: true

module Gobi
  Slice.register_provider :gobi_sftp do
    start do
      gobi_sftp = Shared::Sftp.new(sftp_host: target['settings'].gobi_sftp_host,
                                   sftp_username: target['settings'].gobi_sftp_user,
                                   sftp_password: target['settings'].gobi_sftp_password,
                                   allow_less_secure_algorithms: true)
      register 'gobi_sftp', gobi_sftp
    end
  end
end
