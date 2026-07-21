# frozen_string_literal: true
class ApplicationController < ActionController::Base
  helper_method :application_name, :current_year, :library_header_menu_items

  def application_name
    t(:application_name)
  end

  def current_year
    Time.zone.today.year
  end

  def library_header_menu_items
    Shared::LibraryHeaderMenuItems.new(env: request.env).call
  end

  def new_session_path(_scope)
    new_user_session_path
  end

  private

  def verify_admin!
    authenticate_user!
    redirect_to '/users/auth/cas' unless current_user.admin?
  end
end
