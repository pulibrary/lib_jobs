# frozen_string_literal: true

module Shared
  Slice.register_provider :oclc_sftp do
    start do
      oclc_sftp = Sftp.new(sftp_host: target['settings'].oclc_sftp_host,
                           sftp_username: target['settings'].oclc_sftp_username,
                           sftp_password: target['settings'].oclc_sftp_password)
      register 'oclc_sftp', oclc_sftp
    end
  end
end
