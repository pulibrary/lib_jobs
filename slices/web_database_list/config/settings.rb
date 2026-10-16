module WebDatabaseList
  class Settings < Hanami::Settings
    setting :libguides_client_id, constructor: Types::String, default: '630'
    setting :libguides_client_secret, constructor: Types::String
  end
end
