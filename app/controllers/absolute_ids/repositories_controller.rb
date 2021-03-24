# frozen_string_literal: true

class AbsoluteIds::RepositoriesController < ApplicationController
  skip_forgery_protection if: :token_header?

  # GET /absolute-ids/repositories.json
  def index
    @repositories ||= current_client.repositories

    respond_to do |format|
      format.json { render json: @repositories }
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
end
