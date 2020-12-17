# frozen_string_literal: true
class ApplicationController < ActionController::Base
  helper_method :application_name, :current_year

  def application_name
    "Lib Jobs"
  end

  def current_year
    Date.today.year
  end
end
