# frozen_string_literal: true
class AbsoluteIdCreateRecordJob < ApplicationJob
  def perform(properties:, user_id:)
    @user_id = user_id
    @index = properties[:index]

    create_absolute_id(properties, @index)
  end

  def self.polymorphic_perform_now(**args)
    properties = args[:properties]
    source = properties.delete(:source)
    args[:properties] = properties

    case source
    when 'aspace'
      ::AbsoluteIdCreateAspaceSourceRecordJob.perform_now(**args)
    when 'marc'
      ::AbsoluteIdCreateMarcSourceRecordJob.perform_now(**args)
    else
      perform_now(**args)
    end
  end

  def self.polymorphic_perform_later(**args)
    properties = args[:properties]
    source = properties.delete(:source)
    args[:properties] = properties

    case source
    when 'aspace'
      ::AbsoluteIdCreateAspaceSourceRecordJob.perform_later(**args)
    when 'marc'
      ::AbsoluteIdCreateMarcSourceRecordJob.perform_later(**args)
    else
      perform_later(**args)
    end
  end

  private

  def container_attributes(attr)
    container_resource = JSON.parse(attr.to_json)
    container_resource.delete(:create_time)
    container_resource.delete(:system_mtime)
    container_resource.delete(:user_mtime)

    container_resource.to_json
  end

  def location_attributes(attr)
    attr.to_json
  end

  def transform_repository_properties(attr)
    repository_resource = JSON.parse(attr.to_json)
    repository_resource.delete(:create_time)
    repository_resource.delete(:system_mtime)
    repository_resource.delete(:user_mtime)

    repository_resource.to_json
  end

  def resource_attributes(attr)
    ead_resource = JSON.parse(attr.to_json)
    ead_resource.delete(:create_time)
    ead_resource.delete(:system_mtime)
    ead_resource.delete(:user_mtime)

    ead_resource.to_json
  end

  def container_profile_attributes(attr)
    container_profile_resource = attr
    container_profile_resource.delete(:create_time)
    container_profile_resource.delete(:system_mtime)
    container_profile_resource.delete(:user_mtime)

    container_profile_resource.to_json
  end

  def resolve_resource(repository, ead_id)
    resource_refs = current_client.find_resources_by_ead_id(repository_id: repository.id, ead_id: ead_id)
    resource = repository.build_resource_from(refs: resource_refs)

    raise(ArgumentError, "Failed to resolve the repository resources for #{ead_id} in repository #{repository.id}") if resource.nil?
    resource
  end

  def resolve_container(resource, index)
    top_containers = resource.search_top_containers_by(index: index)
    top_container = top_containers.first

    raise(ArgumentError, "Failed to resolve the containers for #{indicator} in resource #{resource.id}") if top_container.nil?
    top_container
  end

  def transform_aspace_properties(properties, index)
    transformed = properties.deep_dup

    # Resolve the Repository
    repository_param = properties[:repository]
    repository_uri = repository_param[:uri]
    repository = current_client.find_repository(uri: repository_uri)

    # Build the repository attributes
    repository_property = properties[:repository]
    transformed[:repository] = transform_repository_properties(repository_property)

    # Resolve the Resource
    resource_property = properties[:resource]
    resource = resolve_resource(repository, resource_property)

    # Resolve the TopContainer
    container_param = properties[:container]

    indicator = container_param.to_i + index
    top_container = resolve_container(resource, indicator.to_s)

    # Build the repository attributes
    location = location_attributes(properties[:location])
    transformed[:location] = location

    # Build the repository attributes
    container_profile_property = properties[:container_profile]
    container_profile = container_profile_attributes(container_profile_property)
    transformed[:container_profile] = container_profile

    # Build the resource attributes
    transformed[:resource] = resource_attributes(resource)

    # Build the container attributes
    transformed[:container] = container_attributes(top_container)

    transformed
  rescue Errno::ECONNREFUSED => connection_error
    Rails.logger.warn("Failed to connect to the ArchivesSpace REST API: #{error}")
    raise connection_error
  end

  def create_absolute_id(properties, index)
    build_attributes = properties.deep_dup

    source = properties[:source]
    build_attributes = transform_aspace_properties(properties, index) if source == 'aspace'

    # Increment the index
    location = build_attributes[:location]
    container_profile = build_attributes[:container_profile]

    persisted = AbsoluteId.where(location: location, container_profile: container_profile)
    if !persisted.empty?
      # This should not need to be case into an Integer, but this is in place for a PostgreSQL error
      index = persisted.last.index.to_i + 1
    elsif index.zero?
      index = 1
    end

    # This should not need to be case into an Integer, but this is in place for a PostgreSQL error
    build_attributes[:index] = index.to_s

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
