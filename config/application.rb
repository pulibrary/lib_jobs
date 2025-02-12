# frozen_string_literal: true
require_relative 'boot'

require 'rails/all'
require_relative "lando_env"
require_relative File.join('..', 'lib', 'lib_jobs')

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

require 'zip'

module IlsApps
  class Application < Rails::Application
    config.flipflop.dashboard_access_filter = :verify_admin!

    # By default, when set to `nil`, strategy loading errors are suppressed in test
    # mode. Set to `true` to always raise errors, or `false` to always warn.
    config.flipflop.raise_strategy_errors = false

    def config_for(name, env: Rails.env)
      build = super(name, env:)
      OpenStruct.new(build)
    end

    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
    config.staff_directory = config_for(:staff_directory)

    config.cas = config_for(:cas)
    config.x.after_sign_out_url = config.cas.after_sign_out_url

    config.cache_store = :memory_store, { size: 64.megabytes }

    config.alma_sftp = config_for(:alma_sftp)
    config.gobi_sftp = config_for(:gobi_sftp)
    config.gobi_locations = config_for(:gobi_locations)
    config.oclc_sftp = config_for(:oclc_sftp)
    config.lc_call_slips = config_for(:lc_call_slips)
    config.peoplesoft = config_for(:peoplesoft)
    config.pod = config_for(:pod)
    config.aspace = config_for(:aspace)
    config.scsb_s3 = config_for(:scsb_s3)

    # The following two settings - support_unencrypted_data and extend_queries - should
    # *only* be set to true during the transition period to using encrypted data
    config.active_record.encryption.support_unencrypted_data = true
    config.active_record.encryption.extend_queries = true
    # Use environment variables from Princeton Ansible for encryption
    config.active_record.encryption.primary_key = ENV['ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY']
    config.active_record.encryption.deterministic_key = ENV['ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY']
    config.active_record.encryption.key_derivation_salt = ENV['ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT']
  end
end

Zip.continue_on_exists_proc = true
