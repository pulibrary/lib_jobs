# frozen_string_literal: true

class AbsoluteIdsController < ApplicationController
  helper_method :index_status, :table_columns
  skip_forgery_protection if: :token_header?

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

  # This should be moved to a separate controller
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

  # This needs to be moved to another controller
  # POST /absolute-ids
  def create_batches
    authorize! :create_batches, AbsoluteId
    @session = ::AbsoluteIdCreateSessionJob.perform_now(session_attributes: session_params, user_id: current_user.id)

    respond_to do |format|
      format.html do
        redirect_to absolute_ids_path
      end

      format.json do
        head :found, location: absolute_ids_path(format: :json)
      end
    end
  rescue CanCan::AccessDenied
    warning_message = if current_user_params.nil? || current_user.nil?
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
    Rails.logger.warn(JSON.generate(session_params))
    raise error
  end

  # POST /absolute-ids/synchronize
  # POST /absolute-ids/synchronize.json
  def synchronize
    authorize! :synchronize, AbsoluteId

    session_id = params[:session_id]
    @session = AbsoluteId::Session.find_by(user: current_user, id: session_id)
    @absolute_ids = @session.absolute_ids

    @absolute_ids.each do |absolute_id|
      ArchivesSpaceSyncJob.perform_now(user_id: current_user.id, model_id: absolute_id.id)
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

  def session_params
    params.permit(batches: [
                    :barcode,
                    :batch_size,
                    :source,
                    :valid,
                    absolute_id: [
                      :barcode,
                      :container,
                      container_profile: [
                        :create_time,
                        :id,
                        :lock_version,
                        :system_mtime,
                        :uri,
                        :user_mtime,
                        :name,
                        :prefix
                      ],
                      location: [
                        :create_time,
                        :id,
                        :lock_version,
                        :system_mtime,
                        :uri,
                        :user_mtime,
                        :area,
                        :barcode,
                        :building,
                        :classification,
                        :external_ids,
                        :floor,
                        :functions,
                        :room,
                        :temporary
                      ],
                      repository: [
                        :create_time,
                        :id,
                        :lock_version,
                        :system_mtime,
                        :uri,
                        :user_mtime,
                        :name,
                        :repo_code
                      ],
                      resource: [
                        :create_time,
                        :id,
                        :lock_version,
                        :system_mtime,
                        :uri,
                        :user_mtime,
                        :name,
                        :repo_code
                      ]
                    ]
                  ])

    elements = params.permit!.fetch(:batches, [])
    elements.map(&:to_h).map(&:deep_dup)
  end
end
