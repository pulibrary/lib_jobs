# frozen_string_literal: true

class AbsoluteIdsController < ApplicationController
  helper_method :index_status, :table_columns
  skip_forgery_protection if: :token_header?

  def table_columns
    [
      { name: 'user', display_name: 'User', align: 'left', sortable: false },
      { name: 'barcode', display_name: 'Barcode', align: 'left', sortable: true, ascending: 'undefined' },
      { name: 'label', display_name: 'Identifier', align: 'left', sortable: true },
      { name: 'location', display_name: 'Location', align: 'left', sortable: true },
      { name: 'container_profile', display_name: 'Container Profile', align: 'left', sortable: true },
      { name: 'repository', display_name: 'Repository', align: 'left', sortable: false },
      { name: 'resource', display_name: 'Resource', align: 'left', sortable: false },
      { name: 'container', display_name: 'Container', align: 'left', sortable: true }
    ]
  end

  # Remove this
  def next_code
    absolute_ids = AbsoluteId.all
    # This should be a constant
    return '0000000000000' if absolute_ids.empty?

    last_absolute_id = absolute_ids.last
    next_integer = last_absolute_id.integer.to_i + 1
    format("%012d", next_integer)
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

  # POST /absolute-ids/batches
  # POST /absolute-ids/batches.json
  def create_batches
    # authorize! :create_batches, AbsoluteId

    @batches = absolute_id_batches.map { |batch_params|
      batch_size = batch_params[:batch_size]

      children = batch_size.times.map do |_child_index|
        params_valid = batch_params[:valid]

        absolute_id = if params_valid

                        absolute_id_params = batch_params[:absolute_id]
                        binding.pry

                        repository_param = absolute_id_params[:repository]
                        repository_id = repository_param[:id]
                        repository_uri = repository_param[:uri]
                        repository = current_client.find_repository(uri: repository_uri)

                        resource_param = absolute_id_params[:resource]
                        container_param = absolute_id_params[:container]

                        resource_refs = current_client.find_resources_by_ead_id(repository_id: repository_id, ead_id: resource_param)
                        raise ArgumentError if resource_refs.empty?

                        resource = repository.build_resource_from(refs: resource_refs)

                        container_docs = current_client.search_top_containers_by(repository_id: repository_id, query: container_param)
                        raise ArgumentError if container_docs.empty?

                        top_container = repository.build_top_container_from(documents: container_docs)
                        absolute_id_params[:container] = top_container

                        absolute_id_params[:resource] = resource

                        AbsoluteId.generate(**absolute_id_params)
                      else
                        raise ArgumentError
                      end
      end

      if !children.empty?
        batch = AbsoluteId::Batch.create(absolute_ids: children, user: current_user)
        batch.save
        batch
      end
    }.flatten

    if !@batches.empty?
      @session = AbsoluteId::Session.create(batches: @batches, user: current_user)
      @session.save
    end

    respond_to do |format|
      format.html do
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
  rescue ArgumentError => error
    Rails.logger.warn("Failed to create a new Absolute ID with invalid parameters.")
    Rails.logger.warn(JSON.generate(absolute_id_batches))

    respond_to do |format|
      format.json { head(400) }
    end
  end

  # POST /absolute-ids/synchronize
  # POST /absolute-ids/synchronize.json
  def synchronize
    authorize! :synchronize, AbsoluteId

    @absolute_ids ||= AbsoluteId.all.map do |absolute_id|
      job = ArchivesSpaceSyncJob.perform_now(user_id: current_user.id, absolute_id_id: absolute_id.id)
      absolute_id.reload
    end

    respond_to do |format|
      format.html { render :index }
      format.json { render json: @absolute_ids }
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

  # Deprecate
  def build_resource_from(repository_id:, refs:)
    resource_ref = refs.first

    repository_attributes = {
      client: current_client,
      id: repository_id,
      uri: "repositories/#{repository_id}"
    }

    repository = LibJobs::ArchivesSpace::Repository.new(repository_attributes)

    ref_path = resource_ref['ref']
    segments = ref_path.split('/')
    resource_id = segments.last

    repository.find_resource(id: resource_id)
  end

  # Deprecate
  # Move to ArchivesSpace::LibJobs::TopContainer.build_container_from
  def build_container_from(repository_id:, documents:)
    container_doc = documents.first
    parsed = JSON.parse(container_doc['json'])

    response_body_json = parsed.transform_keys(&:to_sym)

    repository_json = { uri: "#{current_client.config.base_uri}/repositories/#{repository_id}" }
    repository_obj = OpenStruct.new(repository_json)
    response_body_json[:repository] = repository_obj

    LibJobs::ArchivesSpace::TopContainer.new(**response_body_json)
  end

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
