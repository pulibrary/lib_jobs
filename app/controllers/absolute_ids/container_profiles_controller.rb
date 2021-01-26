# frozen_string_literal: true

class AbsoluteIds::ContainerProfilesController < ApplicationController
  skip_forgery_protection if: :token_header?

  # GET /absolute-ids/container-profiles.json
  def index
    # @locations ||= AbsoluteId::Location.all
    @container_profiles = [
      {
        "name" => "L959GY311",
        "url" => "DKQ829S",
        "dimension_units" => "inches",
        "extent_dimension" => "width",
        "depth" => "42",
        "height" => "56",
        "width" => "93",
        "id" => "1",
        "uri" => "http://test"
      }
    ]

    respond_to do |format|
      format.json { render json: @container_profiles }
    end
  end

  private

  def value
    params[:value]
  end

  def current_user_params
    params[:user]
  end

  def current_user_id
    current_user_params[:id]
  end

  def token_header
    value = request.headers['Authorization']
    return if value.nil?

    value.gsub(/\s*?Bearer\s*/i, '')
  end

  def token_header?
    token_header.present?
  end

  def current_user_token
    token_header || current_user_params[:token]
  end

  def find_user
    User.find_by(id: current_user_id, token: current_user_token)
  end

  def current_user
    return super if !super.nil? || current_user_params.nil?

    @current_user ||= find_user
  end
end
