# frozen_string_literal: true
class AbsoluteIdCreateMarcSourceRecordJob < AbsoluteIdCreateRecordJob
  def perform(properties:, user_id:)
    @user_id = user_id
    @index = properties[:index]

    create_absolute_id(properties, @index)
  end

  private

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

  def container_profile_attributes(attr)
    container_profile_resource = attr
    container_profile_resource.delete(:create_time)
    container_profile_resource.delete(:system_mtime)
    container_profile_resource.delete(:user_mtime)

    container_profile_resource.to_json
  end

  def transform_aspace_properties(properties, _index)
    transformed = properties.deep_dup

    # Build the repository attributes
    repository_property = properties[:repository]
    transformed[:repository] = transform_repository_properties(repository_property)

    # Resolve the Resource
    resource_property = properties[:resource]
    resource = resource_property

    # Resolve the TopContainer
    top_container = properties[:container]

    # Build the repository attributes
    location = location_attributes(properties[:location])
    transformed[:location] = location

    # Build the repository attributes
    container_profile_property = properties[:container_profile]
    container_profile = container_profile_attributes(container_profile_property)
    transformed[:container_profile] = container_profile

    # Build the resource attributes
    transformed[:resource] = resource

    # Build the container attributes
    transformed[:container] = top_container

    transformed
  rescue Errno::ECONNREFUSED => connection_error
    Rails.logger.warn("Failed to connect to the ArchivesSpace REST API: #{error}")
    raise connection_error
  end

  def create_absolute_id(properties, index)
    build_attributes = transform_aspace_properties(properties.deep_dup, index)

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
