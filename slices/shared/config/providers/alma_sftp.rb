# frozen_string_literal: true

module Shared
  Slice.register_provider :alma_sftp do
    start do
      alma_sftp = Sftp.new(sftp_host: target['settings'].sftp_host,
                           sftp_username: target['settings'].sftp_username,
                           sftp_password: target['settings'].sftp_password)
      register 'alma_sftp', alma_sftp
    end
  end
end
