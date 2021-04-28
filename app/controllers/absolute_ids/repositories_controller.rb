# frozen_string_literal: true

class AbsoluteIds::RepositoriesController < ApplicationController
  skip_forgery_protection if: :token_header?
  include TokenAuthorizedController

  # GET /absolute-ids/repositories.json
  def index
    @repositories ||= current_client.repositories

    respond_to do |format|
      format.json { render json: @repositories }
    end
  end
end
