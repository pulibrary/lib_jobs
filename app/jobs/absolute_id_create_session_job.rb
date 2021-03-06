class AbsoluteIdCreateSessionJob < ApplicationJob
  def perform(session_attributes:, user_id:)
    @user_id = user_id
    create_session(session_attributes)
  end

  private

  def container_attributes(attr)
    container_resource = JSON.parse(attr.to_json)
    container_resource.delete(:create_time)
    container_resource.delete(:system_mtime)
    container_resource.delete(:user_mtime)

    container_resource
  end

  def location_attributes(attr)
    JSON.parse(attr.to_json)
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

  def resolve_resource(repository, ead_id)
    resource_refs = current_client.find_resources_by_ead_id(repository_id: repository.id, ead_id: ead_id)
    resource = repository.build_resource_from(refs: resource_refs)

    raise(ArgumentError, "Failed to resolve the repository resources for #{resource_param} in repository #{repository.id}") if resource.nil?
    resource
  end

  def resolve_container(resource, indicator)
    top_containers = resource.search_top_containers_by(indicator: indicator)
    top_container = top_containers.first

    raise(ArgumentError, "Failed to resolve the containers for #{indicator} in resource #{resource.id}") if top_container.nil?
    top_container
  end

  def create_absolute_id(absolute_id_params, index)
    # Resolve the Repository
    repository_param = absolute_id_params[:repository]
    repository_id = repository_param[:id]
    repository_uri = repository_param[:uri]
    repository = current_client.find_repository(uri: repository_uri)

    # Resolve the Resource
    resource_param = absolute_id_params[:resource]
    resource = resolve_resource(repository, resource_param)

    # Resolve the TopContainer
    container_param = absolute_id_params[:container]
    #top_container = resolve_container(resource, container_param[:indicator])

    indicator = container_param.to_i + index
    top_container = resolve_container(resource, indicator.to_s)

    build_attributes = absolute_id_params.deep_dup

    # Build the repository attributes
    location_resource = location_attributes(build_attributes[:location])
    build_attributes[:location] = location_resource

    # Build the repository attributes
    container_profile_resource = container_profile_attributes(build_attributes[:container_profile])
    build_attributes[:container_profile] = container_profile_resource

    # Build the repository attributes
    build_attributes[:repository] = repository_attributes(build_attributes[:repository])

    # Build the resource attributes
    build_attributes[:resource] = resource_attributes(resource)

    # Build the container attributes
    build_attributes[:container] = container_attributes(top_container)

    # Increment the index
    persisted = AbsoluteId.where(location: location_resource.to_json, container_profile: container_profile_resource.to_json)
    if !persisted.empty?
      # This should not need to be case into an Integer, but this is in place for a PostgreSQL error
      index += persisted.last.index.to_i
    end
    # This should not need to be case into an Integer, but this is in place for a PostgreSQL error
    build_attributes[:index] = index.to_s

    # Update the barcode
    new_barcode_value = build_attributes[:barcode]
    new_barcode = AbsoluteIds::Barcode.new(new_barcode_value)
    new_barcode = new_barcode + index.to_i
    build_attributes[:barcode] = new_barcode.value

    # Build and persist the AbId
    generated = AbsoluteId.generate(**build_attributes)
    generated.save!
    generated
  end

  def create_batch(batch_properties)
    batch_size = batch_properties[:batch_size]
    params_valid = batch_properties[:valid]
    raise ArgumentError unless params_valid

    # Use the same set of params for each AbID
    absolute_id_params = batch_properties[:absolute_id]

    children = batch_size.times.map { |child_index| create_absolute_id(absolute_id_params, child_index) }
    if !children.empty?
      batch = AbsoluteId::Batch.create(absolute_ids: children, user: current_user)
      batch.save!
      Rails.logger.info("Batch created: #{batch.id}")
      batch
    end
  end

  def create_session(session_attributes)
    @batches = session_attributes.map { |batch_params| create_batch(batch_params) }
    if !@batches.empty?
      @session = AbsoluteId::Session.create(batches: @batches, user: current_user)
      @session.save!
      Rails.logger.info("Session created: #{@session.id}")
      @session
    end
  end

  def current_user
    @current_user ||= User.find_by(id: @user_id)
  end

  def current_client
    @current_client ||= begin
                          source_client = LibJobs::ArchivesSpace::Client.source
                          source_client.login
                          source_client
                        end
  end


end
