# frozen_string_literal: true
class ArchivesSpaceSyncJob < ApplicationJob
  queue_as :default

  def perform(user_id:, model_id:)
    @user_id = user_id
    @model_id = model_id

    return if container.to_h.empty?
    return if location.to_h.empty?

    begin
      update_top_container(uri: container.uri, barcode: absolute_id.barcode, indicator: absolute_id.label, location: location)
      absolute_id.synchronized_at = DateTime.current
    rescue StandardError => error
      Rails.logger.warn("Warning: Failed to synchronize #{absolute_id.label}: #{error}")
    end

    absolute_id.synchronizing = false
    absolute_id.save!
    absolute_id
  end

  private

  def user
    @user ||= User.find(@user_id)
  end

  def absolute_id
    @absolute_id ||= AbsoluteId.find_by(id: @model_id)
  end

  def container
    absolute_id.container_object
  end

  def location
    absolute_id.location_object
  end

  def repository
    absolute_id.repository_object
  end

  class ArchivesSpaceClientMapper
    def self.root_config_file_path
      Rails.root.join('config', 'archives_space', 'mapper')
    end

    def self.sync_config_file_path
      root_config_file_path.join('sync.yml')
    end

    def self.sync_config_erb
      io_stream = IO.read(sync_config_file_path)
      erb_document = ERB.new(io_stream)
      erb_document.result(binding)
    end

    def self.sync_config
      parsed = YAML.safe_load(sync_config_erb)
      OpenStruct.new(**parsed.symbolize_keys)
    rescue StandardError, SyntaxError => e
      raise("#{yaml_file_path} was found, but could not be parsed: \n#{e.inspect}")
    end

    def sync_client
      @sync_client ||= begin
                        client = LibJobs::ArchivesSpace::Client.sync
                        client.login
                        client
                      end
    end

    def initialize(source_repository:)
      @source_repository = source_repository
    end

    def sync_repository
      @sync_repository = find_sync_repository(uri: @source_repository.uri)
    end

    def find_sync_repository(uri:)
      #mapped_uri = self.class.find_sync_repository_uri(uri)
      sync_client.find_repository(uri: uri)
    end

    def find_sync_location(uri:)
      #mapped_uri = self.class.find_sync_location_uri(uri)
      sync_client.find_location(uri: uri)
    end

    def find_sync_top_container(uri:)
      #mapped_uri = self.class.find_sync_container_uri(uri)
      sync_repository.find_top_container(uri: uri)
    end
  end

  def client_mapper
    @aspace_space_client ||= ArchivesSpaceClientMapper.new(source_repository: repository)
  end

  def update_top_container(uri:, barcode:, indicator:, location:)
    # This is where the wrong container is retrieved
    sync_container = client_mapper.find_sync_top_container(uri: uri, locations: location)
    if sync_container.nil?
      raise ArchivesSpaceSyncError, "Failed to locate the container resource for #{uri}"
    end

    current_locations = container.container_locations

    sync_location = client_mapper.find_sync_location(uri: location.uri)
    if sync_location.nil?
      raise ArchivesSpaceSyncError, "Failed to locate the location resource for #{location.uri}"
    end

    location_models = current_locations.map do |attrs|
      LibJobs::ArchivesSpace::Location.new(attrs)
    end

    updated_locations = location_models.reject do |location_model|
      location_model.uri.to_s == sync_location.uri.to_s
    end

    updated = sync_container.update(barcode: barcode.value, indicator: indicator, container_locations: updated_locations)
    raise ArchivesSpaceSyncError("Failed to update the container: #{sync_container.uri}") if updated.nil?
  end
end
