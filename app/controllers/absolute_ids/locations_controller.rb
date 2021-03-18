# frozen_string_literal: true

class AbsoluteIds::LocationsController < ApplicationController
  skip_forgery_protection if: :token_header?

  # GET /absolute-ids/locations.json
  def index
    @locations ||= current_client.locations

    respond_to do |format|
      format.json { render json: @locations }
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
