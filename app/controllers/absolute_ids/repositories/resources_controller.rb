# frozen_string_literal: true

class AbsoluteIds::Repositories::ResourcesController < ApplicationController
  skip_forgery_protection if: :token_header?
  include TokenAuthorizedController

  # GET /absolute-ids/repositories/repository_id/resources.json
  def index
    begin
      @resources ||= current_repository.resources
    rescue StandardError => error
      Rails.logger.warn("Failed to resolve the resources for the repository #{repository_id}: #{error}")
      @resources = []
    end

    respond_to do |format|
      format.json { render json: @resources }
    end
  end

  # GET /absolute-ids/repositories/:repository_id/resources/:resource_id.json
  def show
    begin
      @resource ||= current_repository.find_resource_by(id: resource_id)
    rescue StandardError => error
      Rails.logger.warn("Failed to resolve the resource #{resource_id} for the repository #{repository_id}: #{error}")
      @resource = nil
    end

    respond_to do |format|
      format.json { render json: @resource }
    end
  end

  # POST /absolute-ids/repositories/:repository_id/resources/search.json
  def search
    begin
      resource_refs = current_client.find_resources_by_ead_id(repository_id: repository_id, ead_id: ead_id)
      @resource = current_repository.build_resource_from(refs: resource_refs)
    rescue StandardError => error
      Rails.logger.warn("Failed to query for resources using #{ead_id} for the repository #{repository_id}: #{error}")
      @resource = nil
    end

    respond_to do |format|
      format.json { render json: @resource }
    end
  end

  private

  def ead_id
    params[:eadId]
  end

  def repository_id
    params[:repository_id]
  end

  def resource_id
    params[:resource_id]
  end

  def current_repository
    @current_repository ||= current_client.find_repository(id: repository_id)
  end
end
