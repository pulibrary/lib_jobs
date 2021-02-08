
class AbsoluteIdBatchImportJob < ApplicationJob
  def perform(barcode_entries:, sequence_entries:)
    @barcode_entries = barcode_entries
    @sequence_entries = sequence_entries

    begin
      entries.each do |row|
        # AbsoluteIdImportJob.perform_now(**row.to_h)
      end
    rescue StandardError => error
      binding.pry
    end
  end

  def barcode_rows
    return @barcode_rows unless @barcode_rows.nil?

    output = {}

    csv_entries = @barcode_entries[(1..-1)]
    csv_entries.each do |barcode_entry|
      primary_key = barcode_entry[0]
      output[primary_key] = barcode_entry[1]
    end

    @barcode_rows = output
  end

  def current_client
    return @current_client unless @current_client.nil?

    @current_client = LibJobs::ArchivesSpace::Client.source
    @current_client.login
    @current_client
  end

  def entries
    output = []

    csv_entries = @sequence_entries[(1..-1)]
    csv_entries.each do |sequence_entry|
      imported_attributes = {}

      barcode_key = sequence_entry[1]
      prefix = sequence_entry[2]
      absolute_id_index = sequence_entry[10]
      call_number = sequence_entry[11]
      repo_code = sequence_entry[12]
      # Is this needed?
      container_type = sequence_entry[13]

      # Barcode
      barcode = barcode_rows[barcode_key]
      imported_attributes[:barcode] = barcode

      # Index
      imported_attributes[:index] = absolute_id_index
      # Is this needed?
      container_indicator = format("%s-%06d", prefix, absolute_id_index)

      # Determine if this has been imported yet
      persisted_absolute_id = AbsoluteId.find_by(value: barcode, index: absolute_id_index)
      if !persisted_absolute_id.nil?
        Rails.logger.warn("Already imported the Absolute ID: #{persisted_absolute_id.label}")
        next
      end

      # Container Profile
      container_profile_name = AbsoluteId.prefixes.invert[prefix]
      container_profiles = current_client.select_container_profiles_by(name: container_profile_name)
      container_profile = container_profiles.first
      if !container_profile.nil?
        imported_attributes[:container_profile] = container_profile
      end

      # Location
      locations = current_client.select_locations_by(classification: repo_code)
      location = locations.first
      if !location.nil?
        imported_attributes[:location] = location
      end

      # Repository
      repositories = current_client.select_repositories_by(repo_code: repo_code)
      repository = repositories.first

      if !repository.nil?
        imported_attributes[:repository] = repository

        # Resource
        resource_refs = current_client.find_resources_by_ead_id(repository_id: repository.id, ead_id: call_number)
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
    end

    output
  end
end
