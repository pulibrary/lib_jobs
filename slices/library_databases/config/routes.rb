# frozen_string_literal: true

module LibraryDatabases
  class Routes < Hanami::Routes
    get '/library-databases(.:format)', to: 'index'
  end
end
