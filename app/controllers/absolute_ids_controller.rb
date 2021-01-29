# frozen_string_literal: true

class AbsoluteIdsController < ApplicationController
  helper_method :index_status, :next_code, :absolute_id_table_columns, :absolute_id_table_data
  skip_forgery_protection if: :token_header?

  def absolute_id_table_columns
    [
      { name: 'label', display_name: 'Identifier', align: 'left', sortable: true },
      { name: 'barcode', display_name: 'Barcode', align: 'left', sortable: true },
      { name: 'location', display_name: 'Location', align: 'left', sortable: true },
      { name: 'container_profile', display_name: 'Container Profile', align: 'left', sortable: true },
      { name: 'repository', display_name: 'Repository', align: 'left', sortable: false },
      { name: 'resource', display_name: 'Resource', align: 'left', sortable: false },
      { name: 'container', display_name: 'Container', align: 'left', sortable: true },
    ]
  end

  def absolute_id_table_data
    @absolute_ids.map do |absolute_id|
      {
        label: absolute_id.label,
        barcode: absolute_id.barcode.value,
        location: { link: absolute_id.location.uri, value: absolute_id.location.building },
        container_profile: { link: absolute_id.container_profile.uri, value: absolute_id.container_profile.name },
        repository: { link: absolute_id.repository.uri, value: absolute_id.repository.name },
        resource: { link: absolute_id.resource.uri, value: absolute_id.resource.title },
        container: { link: absolute_id.container.uri, value: absolute_id.container.indicator },
      }
    end
  end

  def next_location_model
    absolute_ids = AbsoluteId.all
    return if absolute_ids.empty?

    last_absolute_id = absolute_ids.last
    last_absolute_id.location
  end

  # Remove
  def next_location
    next_location_model.value if next_location_model
  end

  # Remove
  def next_prefix
    absolute_ids = if next_location_model
                     AbsoluteId.where(location_id: next_location_model.id)
                   else
                     AbsoluteId.all
                   end
    return AbsoluteId.default_prefix if absolute_ids.empty?

    last_absolute_id = AbsoluteId.last
    last_absolute_id.prefix
  end

  def next_code
    absolute_ids = AbsoluteId.all
    # This should be a constant
    return '0000000000000' if absolute_ids.empty?

    last_absolute_id = absolute_ids.last
    next_integer = last_absolute_id.integer + 1
    format("%012d", next_integer)
  end

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

  # POST /absolute-ids/batch
  # POST /absolute-ids/batch.json
  def create_batch
    authorize! :create_batch, AbsoluteId
    @absolute_ids = absolute_id_batch_params.each do |absolute_id_params|
                      AbsoluteId.generate(**absolute_id_params)
                    end

    respond_to do |format|
      format.html do
        flash[:absolute_ids] = "Failed to generate a new absolute ID. Please contact the administrator." unless @absolute_id.save
        redirect_to absolute_ids_path
      end

      format.json do
        head :found, location: absolute_ids_path(format: :json)
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

  # PATCH /absolute-ids
  # PATCH /absolute-ids.json
  def update
    authorize! :update, AbsoluteId
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

  def absolute_id_batch_params
    output = params.permit(
      batch: [
        {
          absolute_id: [
            :barcode,

            :location_uri,
            :repository_uri,
            :resource_uri,
            :container_uri,
            container_profile: [
              :name,
              :uri
            ],
          ]
        }
      ]
    )
    parsed = output.to_h.deep_symbolize_keys
    parsed.fetch(:batch, [])
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
        ],
      ]
    )
    parsed = output.to_h.deep_symbolize_keys
    parsed.fetch(:absolute_id, {})
  end
end
