# frozen_string_literal: true

class AbsoluteIds::Repositories::ContainersController < ApplicationController
  skip_forgery_protection if: :token_header?
  include TokenAuthorizedController

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

  def repository_id
    params[:repository_id]
  end

  def current_repository
    @current_repository ||= current_client.find_repository(id: repository_id)
  end
end
