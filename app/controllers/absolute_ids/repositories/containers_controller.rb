# frozen_string_literal: true

class AbsoluteIds::Repositories::ContainersController < ApplicationController
  skip_forgery_protection if: :token_header?

  # GET /absolute-ids/repositories/repository_id/resources.json
  def index
    @resources ||= current_repository.top_containers

    respond_to do |format|
      format.json { render json: @resources }
    end
  rescue StandardError => error
    Rails.logger.warn("Failed to retrieve the top containers: #{error}")
    @resources = []
  end

  # GET /absolute-ids/repositories/:repository_id/resources/:resource_id.json
  def show
    begin
      @resource ||= current_repository.find_top_container(id: container_id)
    rescue
      @resource = nil
    end

    respond_to do |format|
      format.json { render json: @resource }
    end
  end

  # POST /absolute-ids/repositories/:repository_id/containers/search.json
  def search
    indicator = params[:indicator]
    ead_id = params[:eadId]

    begin
      current_resource = current_repository.search_resources(ead_id: ead_id)
      top_containers = current_resource.search_top_containers_by(indicator: indicator)

      @resource = top_containers.first
    rescue StandardError => error
      Rails.logger.warn("Failed to find the repository for #{indicator} linked to the resource #{resource_title}: #{error}")
      @resource = nil
    end

    # Refactor/fix this
    if json_request?
      render json: @resource
    else
      respond_to do |format|
        format.json { render json: @resource }
      end
    end
  end

  private

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

  def repository_id
    params[:repository_id]
  end

  def resource_id
    params[:resource_id]
  end

  def current_repository
    @current_client ||= current_client.find_repository(id: repository_id)
  end

  def container_param
    params[:container_param]
  end
end
