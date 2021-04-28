# frozen_string_literal: true

class ServicesController < ApplicationController
  skip_forgery_protection if: :token_header?
  include TokenAuthorizedController

  # GET /services/archivesspace.json
  def show_archivesspace
    @service = current_client
    status = {
      uri: @service.base_uri
    }

    respond_to do |format|
      format.json { render json: status }
    end
  rescue ArchivesSpace::ConnectionError
    respond_to do |format|
      format.json do
        return head(:forbidden)
      end
    end
  end
end
