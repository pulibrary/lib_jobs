# frozen_string_literal: true

class AbsoluteIds::ContainerProfilesController < ApplicationController
  skip_forgery_protection if: :token_header?
  include TokenAuthorizedController

  # GET /absolute-ids/container-profiles.json
  def index
    models = current_client.container_profiles

    # Insert the prefix
    # @note Prefixes are the container profile equivalent in the legacy AbID
    # database. We keep them here for cross-referencing.
    @container_profiles = models.map do |model|
      model.prefix = AbsoluteId.find_prefix(model.name)
      model
    end

    respond_to do |format|
      format.json { render json: @container_profiles }
    end
  end
end
