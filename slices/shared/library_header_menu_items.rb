# frozen_string_literal: true
module Shared
  class LibraryHeaderMenuItems
    def initialize(env:)
      @env = env
    end

    def call = [
      data_sets,
      user_menu
    ]

    private

    attr_reader :env

    include Rails.application.routes.url_helpers

    def current_user = warden.authenticate(scope: :user)

    def warden = env['warden']

    def data_sets = {
      name: 'Data Sets',
      component: 'Data Sets',
      href: '/'
    }

    def log_in = {
      name: 'Log In',
      component: 'Log In',
      href: new_user_session_path,
      method: 'post'
    }

    def log_out = {
      name: 'Log out',
      component: 'Log out',
      href: '/sign_out'
    }

    def turn_jobs_on_and_off = {
      name: 'Turn jobs on and off',
      component: 'Turn jobs on and off',
      href: '/features'
    }

    def user_menu = if current_user
                      logged_in_user_menu
                    else
                      log_in
                    end

    def logged_in_user_menu = {
      name: current_user.email,
      component: current_user.email,
      href: '#',
      children: if current_user.admin?
                  [log_out, turn_jobs_on_and_off]
                else
                  [log_out]
                end
    }
  end
end
