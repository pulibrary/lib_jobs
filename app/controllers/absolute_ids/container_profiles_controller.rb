# frozen_string_literal: true

class AbsoluteIds::ContainerProfilesController < ApplicationController
  skip_forgery_protection if: :token_header?

  # GET /absolute-ids/container-profiles.json
  def index
    models = current_client.container_profiles

    # Insert the prefixes
    @container_profiles = models.map do |model|
      model.prefix = AbsoluteId.find_prefix(model)
      model
    end

    respond_to do |format|
      format.json { render json: @container_profiles }
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
