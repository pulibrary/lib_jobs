# frozen_string_literal: true

module OpenMarcRecords
  class Routes < Hanami::Routes
    get '/open-marc-records', to: 'index'
    get '/open-marc-records/download/:id', id: /\d+/, to: 'download'
  end
end
