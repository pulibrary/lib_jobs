# frozen_string_literal: true
require_relative 'boot'

require 'rails/all'
require_relative File.join('..', 'lib', 'lib_jobs')

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module IlsApps
  class Application < Rails::Application
    def config_for(*args)
      build = super(*args)
      OpenStruct.new(build)
    end

    def archivesspace_config_for(*args)
      build = config_for(*args)
      LibJobs::ArchivesSpace::Configuration.new(build.to_h)
    end

    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
    config.staff_directory = config_for(:staff_directory)

    config.cas = config_for(:cas)
    config.archivesspace = archivesspace_config_for(:archivesspace)
    config.x.after_sign_out_url = config.cas.after_sign_out_url

    config.cache_store = :memory_store, { size: 64.megabytes }
  end
end
