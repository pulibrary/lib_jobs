# frozen_string_literal: true
require 'hanami'

module LibJobsHanami
  class App < Hanami::App
    prepare_container do |container|
      container.autoloader.ignore('app')
    end
  end

  class Action < Hanami::Action
  end
end

Hanami.boot
