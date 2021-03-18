# frozen_string_literal: true
module AbsoluteIds
  class CreateModelFromAspaceJob < CreateModelJob
    def perform(properties:, user_id:)
      @user_id = user_id

      model_attributes = build_model_attributes(**properties.deep_dup)
      model_attributes[:index] = build_model_index(**model_attributes)
      create_absolute_id(**model_attributes)
    end

    private

    def build_container(properties)
      container_resource = JSON.parse(properties.to_json)
      container_resource.delete(:create_time)
      container_resource.delete(:system_mtime)
      container_resource.delete(:user_mtime)

      container_resource.to_json
    end

    # @todo Should this be removed?
    def build_location(properties)
      properties.to_json
    end

    def transform_repository_properties(properties)
      repository_resource = JSON.parse(properties.to_json)
      repository_resource.delete(:create_time)
      repository_resource.delete(:system_mtime)
      repository_resource.delete(:user_mtime)

      repository_resource.to_json
    end

    def build_resource(properties)
      ead_resource = JSON.parse(properties.to_json)
      ead_resource.delete(:create_time)
      ead_resource.delete(:system_mtime)
      ead_resource.delete(:user_mtime)

      ead_resource.to_json
    end

    def build_container_profile(**properties)
      container_profile_resource = properties.deep_dup
      container_profile_resource.delete(:create_time)
      container_profile_resource.delete(:system_mtime)
      container_profile_resource.delete(:user_mtime)

      container_profile_resource.to_json
    end

    def resolve_aspace_resource(repository, ead_id)
      resource_refs = current_client.find_resources_by_ead_id(repository_id: repository.id, ead_id: ead_id)
      aspace_resource = repository.build_resource_from(refs: resource_refs)

      raise(ArgumentError, "Failed to resolve the repository resources for #{ead_id} in repository #{repository.id}") if aspace_resource.nil?
      aspace_resource
    end

    def resolve_container(aspace_resource:, indicator:, index:)
      container_index = indicator.to_i + index

      # top_containers = aspace_resource.search_top_containers_by(index: container_index)
      # /repositories/4/search?q=display_string%3ABox%2020&page=1&type[]=top_container
      top_containers = aspace_resource.repository.search_top_containers_by(index: container_index)
      top_container = top_containers.first

      raise(ArgumentError, "Failed to resolve the container for index #{container_index} linked to the resource #{aspace_resource.id}") if top_container.nil?
      top_container
    end

    # Resolve the Repository
    def resolve_repository(**properties)
      repository_uri = properties[:uri]
      current_client.find_repository(uri: repository_uri)
    end

    # Build the repository attributes
    def build_repository(**properties)
      repository_resource = JSON.parse(properties.to_json)
      repository_resource.delete(:create_time)
      repository_resource.delete(:system_mtime)
      repository_resource.delete(:user_mtime)

      repository_resource.to_json
    end

    def build_model_attributes(**properties)
      transformed = properties.deep_dup

      # Build the Location
      location = build_location(properties[:location])
      transformed[:location] = location

      # Build the repository attributes
      container_profile = build_container_profile(properties[:container_profile])
      transformed[:container_profile] = container_profile

      # Resolve the Repository
      repository = resolve_repository(properties[:repository])

      # Build the repository attributes
      transformed[:repository] = build_repository(properties[:repository])

      # Resolve the Resource
      aspace_resource = resolve_aspace_resource(repository, properties[:resource])

      # Build the resource attributes
      transformed[:resource] = build_resource(aspace_resource)

      # Resolve the TopContainer
      top_container = resolve_container(aspace_resource: aspace_resource, indicator: properties[:container], index: properties[:index])

      # Build the container attributes
      transformed[:container] = build_container(top_container)

      transformed
    rescue Errno::ECONNREFUSED => connection_error
      Rails.logger.warn("Failed to connect to the ArchivesSpace REST API: #{error}")
      raise connection_error
    end
  end
end
