# frozen_string_literal: true

class AbsoluteIds::LocationsController < ApplicationController
  skip_forgery_protection if: :token_header?
  include TokenAuthorizedController

  # GET /absolute-ids/locations.json
  def index
    @locations ||= current_client.locations

    respond_to do |format|
      format.json { render json: @locations }
    end
  end
end
