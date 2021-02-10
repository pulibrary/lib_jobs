# frozen_string_literal: true
class ArchivesSpaceSyncJob < ApplicationJob
  queue_as :default

  def perform(user_id:, absolute_id_id:)
    @user_id = user_id
    @absolute_id_value = absolute_id_id

    update_top_container(uri: container.uri, barcode: absolute_id.barcode, indicator: absolute_id.label, location: location)
  end

  private

  def user
    @user ||= User.find(@user_id)
  end

  def absolute_id
    @absolute_id ||= AbsoluteId.find_by(id: @absolute_id_value)
  end

  def container
    absolute_id.container
  end

  def location
    absolute_id.location
  end

  def repository
    absolute_id.repository
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

    def self.find_sync_location_uri(source_uri)
      sync_config.locations[source_uri]
    end

    def self.find_sync_repository_uri(source_uri)
      sync_config.repositories[source_uri]
    end

    def self.find_sync_container_uri(source_uri)
      sync_config.top_containers[source_uri]
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
      mapped_uri = self.class.find_sync_repository_uri(uri)
      sync_client.find_repository(uri: mapped_uri)
    end

    def find_sync_location(uri:)
      mapped_uri = self.class.find_sync_location_uri(uri)
      sync_client.find_location(uri: mapped_uri)
    end

    def find_sync_top_container(uri:)
      mapped_uri = self.class.find_sync_container_uri(uri)
      sync_repository.find_top_container(uri: mapped_uri)
    end
  end

  def client_mapper
    @aspace_space_client ||= ArchivesSpaceClientMapper.new(source_repository: repository)
  end

  def update_top_container(uri:, barcode:, indicator:, location:)
    #absolute_id.locking_user = user
    #absolute_id.save
    #absolute_id.reload

    sync_container = client_mapper.find_sync_top_container(uri: uri)
    if sync_container.nil?
      raise ArchivesSpaceSyncError, "Failed to locate the container resource for #{uri}"
    end

    current_locations = container.locations

    sync_location = client_mapper.find_sync_location(uri: location.uri)
    if sync_location.nil?
      raise ArchivesSpaceSyncError, "Failed to locate the location resource for #{location.uri}"
    end

    diff = [sync_location] - current_locations
    updated_locations = current_locations + diff

    sync_container.update(barcode: barcode.value, indicator: indicator, container_locations: updated_locations)

    #absolute_id.locking_user = nil
    #absolute_id.synchronized = true
    #absolute_id.synchronized_on = DateTime.now
    #absolute_id.save
  end
end
