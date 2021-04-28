# frozen_string_literal: true
class ArchivesSpaceSyncJob < ApplicationJob
  class ArchivesSpaceSyncError < StandardError; end

  queue_as :default

  def perform(user_id:, model_id:)
    @user_id = user_id
    @model_id = model_id

    return if container.to_h.empty?
    return if location.to_h.empty?

    begin
      absolute_id.synchronizing = true
      absolute_id.synchronize_status = AbsoluteId::SYNCHRONIZING
      absolute_id.save!

      update_top_container(uri: container.uri, barcode: absolute_id.barcode, indicator: absolute_id.label, location: location)
      absolute_id.synchronized_at = DateTime.current
      absolute_id.synchronize_status = AbsoluteId::SYNCHRONIZED
      absolute_id.save!

      absolute_id.save!
    rescue StandardError => error
      Rails.logger.warn("Warning: Failed to synchronize #{absolute_id.label}: #{error}")

      absolute_id.synchronize_status = AbsoluteId::SYNCHRONIZE_FAILED
      absolute_id.save!
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

  class ClientMapper
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

    def source_client
      @source_client ||= begin
                           client = LibJobs::ArchivesSpace::Client.source
                           client.login
                           client
                         end
    end

    def sync_client
      @sync_client ||= begin
                        client = LibJobs::ArchivesSpace::Client.sync
                        client.login
                        client
                      end
    end
  end

  def client_mapper
    @client_mapper ||= ClientMapper.new
  end

  def update_top_container(uri:, barcode:, indicator:, location:)
    sync_client = client_mapper.source_client
    sync_repository = sync_client.find_repository_by(uri: repository.uri)
    sync_container = sync_repository.find_top_container_by(uri: uri)
    raise(ArchivesSpaceSyncError, "Failed to locate the container resource for #{uri}") if sync_container.nil?

    current_locations = container.container_locations
    sync_location = sync_client.find_location_by(uri: location.uri)
    raise(ArchivesSpaceSyncError, "Failed to locate the location resource for #{location.uri}") if sync_location.nil?
    updated_locations = current_locations.map { |location_attrs| LibJobs::ArchivesSpace::Location.new(location_attrs) }.reject do |location_model|
      location_model.uri.to_s == sync_location.uri.to_s
    end

    updated = sync_container.update(barcode: barcode.value, indicator: indicator, container_locations: updated_locations)
    raise(ArchivesSpaceSyncError, "Failed to update the container: #{sync_container.uri}") if updated.nil?
  end
end
