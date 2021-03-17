# frozen_string_literal: true
class AbsoluteIdImportJob < ApplicationJob
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
    persisted_absolute_id = AbsoluteId.find_by(value: barcode)
    unless persisted_absolute_id.nil?
      Rails.logger.warn("Already imported the Absolute ID: #{persisted_absolute_id.label}")
      return persisted_absolute_id
    end

    # Container Profile
    container_profile_name = AbsoluteId.prefixes.invert[prefix]
    container_profiles = client.select_container_profiles_by(name: container_profile_name)
    container_profile = container_profiles.first
    if !container_profile.nil?
      imported_attributes[:container_profile] = container_profile
    else
      imported_attributes[:unencoded_container_profile] = container_profile
    end

    # Location
    locations = client.select_locations_by(classification: repo_code)
    location = locations.first
    if !location.nil?
      imported_attributes[:location] = location
    else
      # Set the repo code for a legacy value
      imported_attributes[:unencoded_location] = repo_code
    end

    # Repository
    repositories = client.select_repositories_by(repo_code: repo_code)
    repository = repositories.first
    if !repository.nil?
      imported_attributes[:repository] = repository

      # Resource
      resource_refs = client.find_resources_by_ead_id(repository_id: repository.id, ead_id: call_number)

      raise(ArgumentError, "Failed to find the Archival Resource for #{call_number}") if resource_refs.empty?

      resource = repository.build_resource_from(refs: resource_refs)
      imported_attributes[:resource] = resource

      # Container
      top_containers = repository.select_top_containers_by(barcode: barcode)
      top_container = top_containers.first

      raise(ArgumentError, "Failed to find the Top Container resource for #{barcode}") if top_container.nil?

      imported_attributes[:container] = top_container
    else
      # Set the legacy repository for a legacy value
      imported_attributes[:unencoded_repository] = repo_code
      imported_attributes[:unencoded_resource] = call_number
      imported_attributes[:unencoded_container] = container_indicator
    end

    new_absolute_id = AbsoluteId.generate(imported_attributes)
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
