class AbsoluteIdCreateJob < ApplicationJob
  def perform(properties:, user_id:)
    @user_id = user_id
    @index = properties[:index]

    create_absolute_id(properties, @index)
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

    raise(ArgumentError, "Failed to resolve the repository resources for #{ead_id} in repository #{repository.id}") if resource.nil?
    resource
  end

  def resolve_container(resource, indicator)
    top_containers = resource.search_top_containers_by(index: indicator)
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
      index = persisted.last.index.to_i + 1
    elsif index == 0
      index = 1
    end

    # This should not need to be case into an Integer, but this is in place for a PostgreSQL error
    build_attributes[:index] = index.to_s

    # Update the barcode
    #new_barcode_value = build_attributes[:barcode]
    #new_barcode = AbsoluteIds::Barcode.new(new_barcode_value)
    #new_barcode = new_barcode + index.to_i
    #build_attributes[:barcode] = new_barcode.value

    # Build and persist the AbId
    generated = AbsoluteId.generate(**build_attributes)
    generated.save!
    generated.id
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
