# frozen_string_literal: true
module Shared
  # This class is responsible for configuring a view to use the shared app layout
  class UseAppLayout
    def call(config)
      config.paths.push Hanami::View::Path.new(Shared::Slice.config.root.join('templates'))
      config.layout = 'app'
    end
  end
end
