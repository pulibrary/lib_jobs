# frozen_string_literal: true
require 'dry-types'

module Gobi
  class Settings < Hanami::Settings
    setting :gobi_sftp_host, constructor: Types::String, default: 'ftp.ybp.com'
    setting :gobi_sftp_user, constructor: Types::String, default: 'gobi'
    setting :gobi_sftp_password, constructor: Types::String, default: 'change_me'
  end
end
