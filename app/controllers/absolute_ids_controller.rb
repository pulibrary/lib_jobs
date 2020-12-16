# frozen_string_literal: true

class AbsoluteIdsController < ApplicationController
  # GET /absolute-ids
  # GET /absolute-ids.json
  def index
    @absolute_ids ||= model.all

    respond_to do |format|
      format.html { render :index }
      format.json { render json: @absolute_ids }
    end
  end

  # GET /absolute-ids/:value
  # GET /absolute-ids/:value.json
  # GET /absolute-ids/:value.xml
  def show
    @absolute_id ||= model.find(value)

    respond_to do |format|
      format.json { render json: @absolute_id }
      format.xml { render xml: @absolute_id }
    end
  end

  # POST /absolute-ids
  # POST /absolute-ids.json
  def create
    authorize! :create, model
    @absolute_id = model.build

    respond_to do |format|
      format.html do
        flash[:absolute_ids] = "Failed to generate a new absolute ID. Please contact the administrator." unless @absolute_id.save
        redirect_to :index
      end

      format.json do
        if @absolute_id.save
          head :found, location: absolute_id_path(value: @absolute_id.value, format: :json)
        else
          head :found, location: absolute_ids_path(format: :json)
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
        redirect_to :index
      end

      format.json { head :forbidden }
    end
  end

  private

  def model
    AbsoluteId
  end

  def value
    params[:value]
  end

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
