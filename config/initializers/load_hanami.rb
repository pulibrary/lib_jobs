# frozen_string_literal: true
require 'hanami'
require 'hanami/view'

# Hanami and Rails each have their own implementation of html_safe.
# Various Rails behavior breaks if it has to use Hanami's html_safe
# behavior (e.g. form helper tags), so we make sure that the Rails
# html_safe is used.  See
# https://discourse.hanakai.org/t/rails-and-hanami-view-dont-get-along/1122
Hanami::View::HTML::StringExtensions.class_eval do
  def html_safe
    ActiveSupport::SafeBuffer.new(self)
  end
end

module LibJobsHanami
  class App < Hanami::App
    prepare_container do |container|
      container.autoloader.ignore('app')
    end

    config.actions.content_security_policy[:script_src] = "'self' 'nonce' https: 'unsafe-eval'"
    config.actions.finalize!(config)
  end

  class Action < Hanami::Action
  end

  module Views
    class Context < Hanami::View::Context
      def library_header_menu_items
        Shared::LibraryHeaderMenuItems.new(env: request.env).call
      end

      def content_security_policy_nonce
        request.env['hanami.content_security_policy_nonce']
      end
    end
  end
end

Hanami.boot
