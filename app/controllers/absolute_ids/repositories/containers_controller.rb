# frozen_string_literal: true

class AbsoluteIds::Repositories::ContainersController < ApplicationController
  skip_forgery_protection if: :token_header?

  # GET /absolute-ids/repositories/repository_id/resources.json
  def index
    #@resources ||= Rails.cache.fetch(index_cache_key, expires_in: cache_expiry) do
    #  current_repository.resources
    #end

    begin
      @resources ||= current_repository.top_containers
    rescue
      @resources = []
    end

    respond_to do |format|
      format.json { render json: @resources }
    end
  end

  # GET /absolute-ids/repositories/:repository_id/resources/:resource_id.json
  def show
    #@resource ||= Rails.cache.fetch(show_cache_key, expires_in: cache_expiry) do
    #  current_repository.find_resource(id: resource_id)
    #end

    begin
      @resource ||= current_repository.find_resource(id: resource_id)
    rescue
      @resource = nil
    end

    respond_to do |format|
      format.json { render json: @resource }
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

  def index_cache_key
    "absolute_ids/repositories/#{repository_id}/resources"
  end

  def show_cache_key
    "absolute_ids/repositories/#{repository_id}resources/#{resource_id}"
  end
end
