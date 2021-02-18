# frozen_string_literal: true

class AbsoluteIdsController < ApplicationController
  helper_method :index_status
  skip_forgery_protection if: :token_header?

  # GET /absolute-ids
  # GET /absolute-ids.json
  def index
    @absolute_ids ||= AbsoluteId.all

    respond_to do |format|
      format.html { render :index }
      format.json { render json: @absolute_ids }
    end
  end

  # GET /absolute-ids/:value
  # GET /absolute-ids/:value.json
  # GET /absolute-ids/:value.xml
  def show
    @absolute_id ||= AbsoluteId.find_by(value: value)

    respond_to do |format|
      format.json { render json: @absolute_id }
      format.xml { render xml: @absolute_id }
    end
  end

  # POST /absolute-ids
  # POST /absolute-ids.json
  def create
    authorize! :create, AbsoluteId
    @absolute_id = AbsoluteId.generate

    respond_to do |format|
      format.html do
        flash[:absolute_ids] = "Failed to generate a new absolute ID. Please contact the administrator." unless @absolute_id.save
        redirect_to absolute_ids_path
      end

      format.json do
        if @absolute_id.nil?
          head :found, location: absolute_ids_path(format: :json)
        else
          head :found, location: absolute_id_path(value: @absolute_id.value, format: :json)
        end
      end
    end
  rescue CanCan::AccessDenied
    warning_message = if current_user_params.nil?
                        "Denied attempt to create an Absolute ID by the anonymous client #{request.remote_ip}"
                      else
                        "Denied attempt to create an Absolute ID by the user ID #{current_user_id}"
                      end

    Rails.logger.warn(warning_message)

    respond_to do |format|
      format.html do
        redirect_to absolute_ids_path
      end

      format.json { head :forbidden }
    end
  end

  def index_status
    "No absolute IDs have been generated yet." if @absolute_ids.empty?
  end

  private

  def value
    params[:value]
  end

  def token_header?
    token_header.present?
  end
end
