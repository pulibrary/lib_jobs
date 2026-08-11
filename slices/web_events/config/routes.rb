# frozen_string_literal: true

module WebEvents
  class Routes < Hanami::Routes
    get '/library-events(.:format)', to: 'index'
  end
end
