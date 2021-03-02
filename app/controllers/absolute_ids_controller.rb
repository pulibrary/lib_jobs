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

  def find_resource(absolute_id_params)
    resource_id = absolute_id_params[:resource_id]
  end

  def find_container(absolute_id_params)
    container_id = absolute_id_params[:container_id]
  end

  def container_attributes(attr)
    container_resource = JSON.parse(attr.to_json)
    container_resource.delete(:create_time)
    container_resource.delete(:system_mtime)
    container_resource.delete(:user_mtime)

    container_resource
  end

  def location_attributes(attr)
    location_resource = JSON.parse(attr.to_json)

    location_resource
  end

  def repository_attributes(attr)
    repository_resource = JSON.parse(attr.to_json)
    repository_resource.delete(:create_time)
    repository_resource.delete(:system_mtime)
    repository_resource.delete(:user_mtime)

    repository_resource
  end

  def resource_attributes(attr)
    ead_resource = JSON.parse(attr.to_json)
    ead_resource.delete(:create_time)
    ead_resource.delete(:system_mtime)
    ead_resource.delete(:user_mtime)

    ead_resource
  end

  def container_profile_attributes(attr)
    container_profile_resource = attr
    container_profile_resource.delete(:create_time)
    container_profile_resource.delete(:system_mtime)
    container_profile_resource.delete(:user_mtime)

    container_profile_resource
  end

  # POST /absolute-ids/batches
  # POST /absolute-ids/batches.json
  def create_batches
    # authorize! :create_batches, AbsoluteId

    @batches = absolute_id_batches.map { |batch_params|
      batch_size = batch_params[:batch_size]

      children = batch_size.times.map do |child_index|

        params_valid = batch_params[:valid]

        absolute_id = if params_valid

                        absolute_id_params = batch_params[:absolute_id]

                        repository_param = absolute_id_params[:repository]
                        repository_id = repository_param[:id]
                        repository_uri = repository_param[:uri]
                        repository = current_client.find_repository(uri: repository_uri)

                        resource_param = absolute_id_params[:resource]
                        container_param = absolute_id_params[:container]

                        resource_refs = current_client.find_resources_by_ead_id(repository_id: repository_id, ead_id: resource_param)
                        raise(ArgumentError, "Failed to resolve the repository resources for #{resource_param} in repository #{repository_id}") if resource_refs.empty?

                        resource = repository.build_resource_from(refs: resource_refs)

                        containers = current_client.search_top_containers_by(repository_id: repository_id, query: container_param)
                        raise(ArgumentError, "Failed to resolve the containers for #{container_param} in repository #{repository_id}") if containers.empty?

                        top_container = containers.first

                        build_attributes = absolute_id_params.deep_dup

                        location_resource = location_attributes(build_attributes[:location])
                        build_attributes[:location] = location_resource

                        container_profile_resource = container_profile_attributes(build_attributes[:container_profile])
                        build_attributes[:container_profile] = container_profile_resource

                        build_attributes[:repository] = repository_attributes(build_attributes[:repository])

                        build_attributes[:resource] = resource_attributes(resource)

                        build_attributes[:container] = container_attributes(top_container)

                        persisted = AbsoluteId.where(location: location_resource.to_json, container_profile: container_profile_resource.to_json)
                        index = child_index
                        if !persisted.empty?
                          index += persisted.last.index.to_i + 1
                        end
                        build_attributes[:index] = index.to_s

                        # Update the barcode
                        new_barcode_value = build_attributes[:barcode]
                        new_barcode = AbsoluteIds::Barcode.new(new_barcode_value)
                        new_barcode = new_barcode + child_index.to_i
                        build_attributes[:barcode] = new_barcode.value

                        generated = AbsoluteId.generate(**build_attributes)
                        generated.save!
                        generated
                      else
                        raise ArgumentError
                      end
      end

      if !children.empty?
        batch = AbsoluteId::Batch.create(absolute_ids: children, user: current_user)
        batch.save!
        Rails.logger.info("Batch created: #{batch.id}")
        batch
      end
    }.flatten

    if !@batches.empty?
      @session = AbsoluteId::Session.create(batches: @batches, user: current_user)
      @session.save!
      Rails.logger.info("Session created: #{@session.id}")
      @session
    end

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
  rescue ArgumentError => error
    Rails.logger.warn("Failed to create a new Absolute ID with invalid parameters.")
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
      ArchivesSpaceSyncJob.perform_now(user_id: current_user.id, model_id: absolute_id.id)
    end

    respond_to do |format|
      format.json do
        head :found, location: absolute_ids_path(format: :json)
      end
    end
  end

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
