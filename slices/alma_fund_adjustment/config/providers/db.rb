require Hanami.app.root.join('lib', 'lib_jobs_hanami', 'providers', 'db_provider')

# The `db` provider configures its gateway URL explicitly here rather than
# relying on `configure_from_parent`, which does not propagate gateways.
# See https://github.com/hanami/hanami/issues/1626
AlmaFundAdjustment::Slice.configure_provider :db do
  config.gateway :default do |gateway|
    LibJobsHanami::Providers::DBProvider.configure_gateway(gateway)
  end
end
