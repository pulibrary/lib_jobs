# frozen_string_literal: true

module AbsoluteIds
  class ImportJob < ApplicationJob
    def resolve_top_container(aspace_resource:, indicator:)
      top_containers = aspace_resource.top_containers.select { |c| c.indicator == indicator || c.indicator =~ /(?:[bB]ox)\s#{indicator}/ }
      top_containers.first
    end

    def perform(sequence_entry)
      prefix = sequence_entry[:prefix]
      index = sequence_entry[:index]
      call_number = sequence_entry[:call_number]
      container_indicator = sequence_entry[:container_indicator]
      repo_code = sequence_entry[:repo_code]
      barcode = sequence_entry[:barcode]

      imported_attributes = {
        index: index,
        barcode: barcode
      }

      # Determine if this has been imported yet
      persisted_absolute_id = ::AbsoluteId.find_by(value: barcode)
      unless persisted_absolute_id.nil?
        Rails.logger.warn("Already imported the Absolute ID: #{persisted_absolute_id.label}")
        return persisted_absolute_id
      end

      # Container Profile
      container_profile_name = ::AbsoluteId.prefixes.invert[prefix]
      container_profiles = client.select_container_profiles_by(name: container_profile_name)
      container_profile = container_profiles.first
      if !container_profile.nil?

        # Container Profile
        container_profile_resource = container_profile.to_h
        container_profile_resource.delete(:create_time)
        container_profile_resource.delete(:system_mtime)
        container_profile_resource.delete(:user_mtime)

        imported_attributes[:container_profile] = container_profile_resource.to_json
      else
        imported_attributes[:container_profile] = container_profile
      end

      # Location
      locations = client.select_locations_by(classification: repo_code)
      location = locations.first
      if !location.nil?

        # Location
        location_resource = location.to_h
        location_resource.delete(:create_time)
        location_resource.delete(:system_mtime)
        location_resource.delete(:user_mtime)

        imported_attributes[:location] = location_resource.to_json
      else
        # Set the repo code for a legacy value
        imported_attributes[:location] = repo_code
      end

      # Find ArchivesSpace Repositories
      repositories = client.select_repositories_by(repo_code: repo_code)
      repository = repositories.first
      if !repository.nil?

        # Repository
        repository_resource = repository.to_h
        repository_resource.delete(:create_time)
        repository_resource.delete(:system_mtime)
        repository_resource.delete(:user_mtime)

        imported_attributes[:repository] = repository_resource.to_json

        # Find ArchivesSpace Resources
        resource_refs = client.find_resources_by_ead_id(repository_id: repository.id, ead_id: call_number)

        raise(ArgumentError, "Failed to find the Archival Resource for #{call_number}") if resource_refs.empty?

        resource = repository.build_resource_from(refs: resource_refs)

        # Resource
        ead_resource = resource.to_h
        ead_resource.delete(:create_time)
        ead_resource.delete(:system_mtime)
        ead_resource.delete(:user_mtime)

        imported_attributes[:resource] = ead_resource.to_json

        # Container
        top_container = resolve_top_container(aspace_resource: resource, indicator: container_indicator)

        if !top_container.nil?
          top_container_resource = top_container.to_h
          top_container_resource.delete(:create_time)
          top_container_resource.delete(:system_mtime)
          top_container_resource.delete(:user_mtime)

          imported_attributes[:container] = top_container_resource.to_json
        else
          imported_attributes[:container] = container_indicator
        end
      else
        # Set the legacy repository for a legacy value
        imported_attributes[:repository] = repo_code
        imported_attributes[:resource] = call_number
        imported_attributes[:container] = container_indicator
      end

      new_absolute_id = ::AbsoluteId.generate(imported_attributes)
      Rails.logger.info("Successfully imported the Absolute ID: #{new_absolute_id.label}")
      new_absolute_id
    end

    private

    def client
      @client ||= begin
                    new_client = LibJobs::ArchivesSpace::Client.source
                    new_client.login
                    new_client
                  end
    end
  end
end
