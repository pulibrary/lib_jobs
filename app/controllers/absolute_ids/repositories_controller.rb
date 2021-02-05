# frozen_string_literal: true

class AbsoluteIds::RepositoriesController < ApplicationController
  skip_forgery_protection if: :token_header?

  # Remove this
  def fixtures
    @repositories = [
      {
        id: 2,
        name: 'Mudd Library',
        repo_code: 'mudd',
        uri: 'http://localhost:8089/repositories/2'
      },
      {
        id: 3,
        name: 'Special Collections',
        repo_code: 'specoll',
        uri: 'http://localhost:8089/repositories/3'
      }
    ]
  end

  # GET /absolute-ids/repositories.json
  def index
    # @repositories ||= Rails.cache.fetch(index_cache_key, expires_in: cache_expiry) do
    #   current_client.repositories
    # end

    begin
      @repositories ||= current_client.repositories
    rescue
      @repositories = []
    end

    # Remove this
    # @repositories = fixtures

    respond_to do |format|
      format.json { render json: @repositories }
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

  def index_cache_key
    "absolute_ids/repositories"
  end
end
