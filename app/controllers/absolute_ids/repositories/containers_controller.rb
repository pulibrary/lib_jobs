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
