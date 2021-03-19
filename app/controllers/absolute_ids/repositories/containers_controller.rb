# frozen_string_literal: true

class AbsoluteIds::Repositories::ContainersController < ApplicationController
  skip_forgery_protection if: :token_header?

  # GET /absolute-ids/repositories/repository_id/containers.json
  def index
    @resources ||=
      begin
        current_repository.top_containers
      rescue StandardError => error
        Rails.logger.warn("Failed to retrieve the top containers: #{error}")
        []
      end
    respond_to do |format|
      format.json { render json: @resources }
    end
  end

  # GET /absolute-ids/repositories/:repository_id/resources/:resource_id.json
  def show
    begin
      @resource ||= current_repository.find_top_container(id: container_id)
    rescue StandardError
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
    rescue StandardError => e
      Rails.logger.warn("Failed to find the repository for #{indicator} linked to the resource #{resource_title}: #{e}")
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

  def token_header
    value = request.headers['Authorization']
    return if value.nil?

    value.gsub(/\s*?Bearer\s*/i, '')
  end

  def token_header?
    token_header.present?
  end

  def repository_id
    params[:repository_id]
  end

  def current_repository
    @current_repository ||= current_client.find_repository(id: repository_id)
  end
end
