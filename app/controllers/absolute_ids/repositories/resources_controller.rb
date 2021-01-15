# frozen_string_literal: true

class AbsoluteIds::Repositories::ResourcesController < ApplicationController
  skip_forgery_protection if: :token_header?

  def current_client
    return @current_client unless @current_client.nil?

    @current_client = LibJobs::ArchivesSpace::Client.default
    @current_client.login
    @current_client
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

  # GET /absolute-ids/repositories/repository_id/resources.json
  def index
    @resources ||= current_repository.resources

    respond_to do |format|
      format.json { render json: @resources }
    end
  end

  # GET /absolute-ids/repositories/:repository_id/resources/:resource_id.json
  def show
    @resource ||= current_repository.find_resource(id: resource_id)

    respond_to do |format|
      format.json { render json: @resource }
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
