require 'dry-types'
module Shared
  class Settings < Hanami::Settings
    setting :sftp_host, constructor: Types::String, default: 'localhost2'
    setting :sftp_username, constructor: Types::String, default: 'alma'
    setting :sftp_password, constructor: Types::String, default: 'change_me'
    setting :oclc_sftp_host, constructor: Types::String, default: 'filex-m1.oclc.org'
    setting :oclc_sftp_username, constructor: Types::String, default: 'fx_pul'
    setting :oclc_sftp_password, constructor: Types::String, default: 'test_oclc_pass'
  end
end
