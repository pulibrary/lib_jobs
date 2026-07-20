# frozen_string_literal: true

module RecentJobStatuses
  class Routes < Hanami::Routes
    get '/status', to: 'index'
  end
end
