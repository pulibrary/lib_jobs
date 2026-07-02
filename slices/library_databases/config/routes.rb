# frozen_string_literal: true

module LibraryDatabases
  class Routes < Hanami::Routes
    get '/library-databases', to: 'index'
    get '/library-databases.csv', to: 'index'
  end
end
