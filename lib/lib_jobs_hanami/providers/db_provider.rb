module LibJobsHanami
  module Providers
    module DBProvider
      extend self

      def configure_gateway(gateway)
        gateway.database_url = if Rails.env && Rails.configuration.database_configuration
                                 db_config = Rails.configuration.database_configuration[Rails.env]
                                 if db_config['username'] && db_config['password']
                                   "postgres://#{db_config['username']}:#{db_config['password']}@#{db_config['host']}:#{db_config['port'] || '5432'}/#{db_config['database']}"
                                 else
                                   "postgres://#{db_config['host']}:#{db_config['port'] || '5432'}/#{db_config['database']}"
                                 end
                               end

        gateway.adapter :sql do |sql|
          sql.extension :activerecord_connection
        end
      end
    end
  end
end
