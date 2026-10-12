require Hanami.app.root.join('lib', 'lib_jobs_hanami', 'providers', 'db_provider')

Shared::Slice.configure_provider :db do
  config.gateway :default do |gateway|
    LibJobsHanami::Providers::DBProvider.configure_gateway(gateway)
  end
end
