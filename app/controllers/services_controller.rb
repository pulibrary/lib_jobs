# frozen_string_literal: true

class ServicesController < ApplicationController
  skip_forgery_protection if: :token_header?

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

  private

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

end
