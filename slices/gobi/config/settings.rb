# frozen_string_literal: true

require 'dry-types'

module Gobi
  class Settings < Hanami::Settings
    setting :gobi_sftp_host, constructor: Types::String, default: 'ftp.ybp.com'
    setting :gobi_sftp_user, constructor: Types::String, default: 'gobi'
    setting :gobi_sftp_password, constructor: Types::String, default: 'change_me'
    setting :gobi_sftp_working_directory, constructor: Types::String, default: '/tmp/gobi'
    setting :gobi_sftp_output_sftp_base_dir, constructor: Types::String, default: '/holdings'
    setting :gobi_account_code, constructor: Types::String, default: '123499'
    setting :gobi_limited_locations, constructor: Types::Array.of(Types::String), default: [
      'arch$ref', 'arch$la', 'eastasian$cjkref', 'eastasian$ref', 'eastasian$hyref', 'engineer$ref', 'firestone$aas',
      'firestone$dra', 'firestone$dr', 'firestone$drrr', 'firestone$flm', 'firestone$sc', 'firestone$se', 'firestone$slav',
      'firestone$sh', 'firestone$shs', 'firestone$sne', 'firestone$spc', 'firestone$sss', 'firestone$ssa', 'firestone$srel',
      'firestone$gestf', 'firestone$dss', 'firestone$fis', 'firestone$sps', 'firestone$seref', 'firestone$egsr', 'firestone$gss',
      'firestone$noncirc', 'firestone$necnc', 'firestone$clasnc', 'firestone$xlnc', 'firestone$secw', 'firestone$ssrcfo',
      'firestone$ssrcdc', 'plasma$ref', 'plasma$rr', 'plasma$la', 'plasma$li', 'plasma$theses', 'plasma$nb', 'lewis$lal',
      'lewis$laf', 'lewis$refid', 'lewis$ref', 'marquand$fesrf', 'marquand$ph', 'marquand$phref', 'marquand$ref', 'mendel$rg',
      'mendel$facs', 'mendel$ref', 'mendel$pe', 'mudd$scamudd', 'rare$gestrare', 'rare$scactsn', 'rare$scathx', 'rare$scahsvm',
      'rare$scagax', 'rare$scaex', 'rare$scamss', 'rare$scawa', 'rare$scahsvc', 'rare$scawhs', 'stokes$ref'
    ].freeze
    setting :gobi_shared_locations, constructor: Types::Array.of(Types::String), default: [
      'recap$pa', 'recap$gp', 'mendel$qk', 'firestone$pf', 'marquand$pv'
    ].freeze
  end
end
