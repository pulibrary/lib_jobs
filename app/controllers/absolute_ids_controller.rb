# frozen_string_literal: true

class AbsoluteIdsController < ApplicationController
  helper_method :index_status, :table_columns
  skip_forgery_protection if: :token_header?
  include TokenAuthorizedController

  def table_columns
    [
      { name: 'label', display_name: 'Identifier', align: 'left', sortable: true },
      { name: 'barcode', display_name: 'Barcode', align: 'left', sortable: true, ascending: 'undefined' },
      { name: 'location', display_name: 'Location', align: 'left', sortable: false },
      { name: 'container_profile', display_name: 'Container Profile', align: 'left', sortable: false },
      { name: 'repository', display_name: 'Repository', align: 'left', sortable: false },
      { name: 'resource', display_name: 'ASpace Resource', align: 'left', sortable: false },
      { name: 'container', display_name: 'ASpace Container', align: 'left', sortable: false },
      { name: 'user', display_name: 'User', align: 'left', sortable: false },
      { name: 'status', display_name: 'Synchronization', align: 'left', sortable: false, datatype: 'constant' }
    ]
  end

  # GET /absolute-ids/:value
  # GET /absolute-ids/:value.json
  # GET /absolute-ids/:value.xml
  def show
    @absolute_id ||= AbsoluteId.find_by(value: value_param)

    respond_to do |format|
      format.json { render json: @absolute_id }
      format.xml { render xml: @absolute_id }
    end
  end

  # POST /absolute-ids
  # POST /absolute-ids.json
  def create
    authorize!(:create, AbsoluteId)
    @absolute_id = AbsoluteId.generate(**absolute_id_params)

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
                        "Denied attempt to create an Absolute ID by the user ID #{current_user.email}"
                      end

    Rails.logger.warn(warning_message)

    respond_to do |format|
      format.html do
        redirect_to absolute_ids_path
      end

      format.json { head :forbidden }
    end
  end

  # PATCH /absolute-ids
  # PATCH /absolute-ids.json
  def update
    authorize!(:update, AbsoluteId)
    @absolute_id = AbsoluteId.create_or_update(**absolute_id_params)

    respond_to do |format|
      format.html do
        # To be implemented
      end

      format.json do
        head :found, location: absolute_id_path(value: @absolute_id.value, format: :json)
      end
    end
  rescue CanCan::AccessDenied
    warning_message = if current_user_params.nil?
                        "Denied attempt to update the Absolute ID by the anonymous client #{request.remote_ip}"
                      else
                        "Denied attempt to update the Absolute ID by the user ID #{current_user_id}"
                      end

    Rails.logger.warn(warning_message)

    respond_to do |format|
      format.html do
        redirect_to absolute_ids_path
      end

      format.json { head :forbidden }
    end
  end

  private

  def value_param
    params[:value]
  end

  def absolute_id_params
    output = params.permit(
      absolute_id: [
        :barcode,
        location: [
          :id,
          :uri,
          :building
        ],
        repository: [
          :id,
          :uri,
          :name,
          :repo_code
        ],
        resource: [
          :id,
          :uri,
          :title
        ],
        container: [
          :id,
          :uri,
          :barcode,
          :indicator
        ],
        container_profile: [
          :id,
          :name,
          :uri
        ]
      ]
    )
    parsed = output.to_h.deep_symbolize_keys
    parsed.fetch(:absolute_id, {})
  end
end
