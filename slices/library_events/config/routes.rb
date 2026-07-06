# frozen_string_literal: true

module LibraryEvents
  class Routes < Hanami::Routes
    get '/library-events(.:format)', to: 'index'
  end
end
