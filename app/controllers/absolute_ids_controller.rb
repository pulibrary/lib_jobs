# frozen_string_literal: true

class AbsoluteIdsController < ApplicationController
  helper_method :index_status, :table_columns
  skip_forgery_protection if: :token_header?

  def table_columns
    [
      { name: 'barcode', display_name: 'Barcode', align: 'left', sortable: true, ascending: 'undefined' },
      { name: 'label', display_name: 'Identifier', align: 'left', sortable: true },
      { name: 'location', display_name: 'Location', align: 'left', sortable: false },
      { name: 'container_profile', display_name: 'Container Profile', align: 'left', sortable: false },
      { name: 'repository', display_name: 'Repository', align: 'left', sortable: false },
      { name: 'resource', display_name: 'ASpace Resource', align: 'left', sortable: false },
      { name: 'container', display_name: 'ASpace Container', align: 'left', sortable: false },
      { name: 'user', display_name: 'User', align: 'left', sortable: false },
      { name: 'synchronized_at', display_name: 'Last Synchronized', align: 'left', sortable: true }
    ]
  end

  # GET /absolute-ids
  # GET /absolute-ids.json
  def index
    @sessions ||= begin
                    models = AbsoluteId::Session.where(user: current_user)
                    models.reverse
                  end

    respond_to do |format|
      format.html { render :index }
      format.json { render json: @sessions }
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

  # This needs to be moved to another controller
  # POST /absolute-ids/batches
  # POST /absolute-ids/batches.json
  def create_batches
    # authorize! :create_batches, AbsoluteId
    @session = ::AbsoluteIdCreateSessionJob.perform_now(session_attributes: absolute_id_batches, user_id: current_user.id)

    respond_to do |format|
      format.html do
        redirect_to absolute_ids_path
      end

      format.json do
        head :found, location: absolute_ids_path(format: :json)
      end

      format.text do
        head :found, location: absolute_ids_path(format: :json)
      end
    end
  rescue CanCan::AccessDenied
    warning_message = if current_user_params.nil?
                        "Denied attempt to create batches of Absolute IDs by the anonymous client #{request.remote_ip}"
                      else
                        "Denied attempt to create batches of Absolute IDs by the user ID #{current_user.id}"
                      end

    Rails.logger.warn(warning_message)

    respond_to do |format|
      format.html do
        redirect_to absolute_ids_path
      end

      format.json { head :forbidden }
    end
  rescue ArgumentError => error
    Rails.logger.warn("Failed to create batches of new Absolute IDs with invalid parameters.")
    Rails.logger.warn(JSON.generate(absolute_id_batches))
    raise error

    respond_to do |format|
      format.json { head(400) }
    end
  end

  # POST /absolute-ids/synchronize
  # POST /absolute-ids/synchronize.json
  def synchronize
    authorize! :synchronize, AbsoluteId

    session_id = params[:session_id]
    @session = AbsoluteId::Session.find_by(user: current_user, id: session_id)
    @batches = @session.batches.to_a
    @absolute_ids = @batches.map(&:absolute_ids).flatten

    @absolute_ids.each do |absolute_id|
      absolute_id.synchronizing = true
      absolute_id.save!
      ArchivesSpaceSyncJob.perform_later(user_id: current_user.id, model_id: absolute_id.id)
    end

    respond_to do |format|
      format.json do
        head :found, location: absolute_ids_path(format: :json)
      end
    end
  end

  # This needs to be moved to another controller
  def show_session
    session_id = params[:session_id]
    @session ||= begin
                   AbsoluteId::Session.find_by(user: current_user, id: session_id)
                 end

    if request.format.text?
      render text: @session.to_txt
    else
      respond_to do |format|
        format.json { render json: @session }
        format.yaml { render yaml: @session.to_yaml }
        format.xml { render xml: @session }
      end
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

  def batches
    @batches ||= begin
                   return [] if @session.nil?

                   @session.batches
                 end
  end

  def absolute_ids
    @absolute_ids ||= begin
                        return [] if @batches.nil?

                        batches.map(&:absolute_ids).flatten
                      end
  end

  def index_status
    "No absolute IDs have been generated yet." if absolute_ids.empty?
  end

  private

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

  def absolute_id_batches
    ActionController::Parameters.permit_all_parameters = true
    parsed = params.to_h.deep_symbolize_keys
    ActionController::Parameters.permit_all_parameters = false

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
        ]
      ]
    )
    parsed = output.to_h.deep_symbolize_keys
    parsed.fetch(:absolute_id, {})
  end
end
