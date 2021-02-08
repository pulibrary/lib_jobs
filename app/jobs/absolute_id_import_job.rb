
class AbsoluteIdImportJob < ApplicationJob
  def perform(sequence_entry)
    prefix = sequence_entry[:prefix]
    index = sequence_entry[:index]
    call_number = sequence_entry[:call_number]
    repo_code = sequence_entry[:repo_code]
    barcode = sequence_entry[:barcode]

    imported_attributes = {
      prefix: prefix,
      index: index,
      call_number: call_number,
      repo_code: repo_code,
      barcode: barcode
    }

    # Is this needed?
    # container_indicator = format("%s-%06d", prefix, index)

    # Determine if this has been imported yet
    persisted_absolute_id = AbsoluteId.find_by(value: barcode)
    if !persisted_absolute_id.nil?
      Rails.logger.warn("Already imported the Absolute ID: #{persisted_absolute_id.label}")
      return persisted_absolute_id
    end

    # Container Profile
    container_profile_name = AbsoluteId.prefixes.invert[prefix]
    container_profiles = aspace_client.select_container_profiles_by(name: container_profile_name)
    container_profile = container_profiles.first
    if !container_profile.nil?
      imported_attributes[:container_profile] = container_profile
    end

    # Location
    locations = aspace_client.select_locations_by(classification: repo_code)
    location = locations.first
    if !location.nil?
      imported_attributes[:location] = location
    end

    # Repository
    repositories = aspace_client.select_repositories_by(repo_code: repo_code)
    repository = repositories.first

    if !repository.nil?
      imported_attributes[:repository] = repository

      # Resource
      resource_refs = aspace_client.find_resources_by_ead_id(repository_id: repository.id, ead_id: call_number)
      if !resource_refs.empty?
        resource = repository.build_resource_from(refs: resource_refs)
        imported_attributes[:resource] = resource
      end

      # Container
      top_containers = repository.select_top_containers_by(barcode: barcode)
      top_container = top_containers.first
      if !top_container.nil?
        imported_attributes[:container] = top_container
      end
    end

    new_absolute_id = AbsoluteId.generate(imported_attributes)
    Rails.logger.info("Successfully imported the Absolute ID: #{new_absolute_id.label}")
    new_absolute_id
  end

  private

  def aspace_client
    return @aspace_client unless @aspace_client.nil?

    @aspace_client = LibJobs::ArchivesSpace::Client.source
    @aspace_client.login
    @aspace_client
  end
end
