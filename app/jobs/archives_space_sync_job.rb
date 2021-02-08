# frozen_string_literal: true
class ArchivesSpaceSyncJob < ApplicationJob
  queue_as :default

  def perform(user_id:, absolute_id_id:)
    @user_id = user_id
    @absolute_id_value = absolute_id_id

    update_top_container(id: container.id, barcode: absolute_id.barcode, indicator: absolute_id.label, location: location)
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

  def sync_client
    return @sync_client unless @sync_client.nil?

    @sync_client = LibJobs::ArchivesSpace::Client.sync
    @sync_client.login
    @sync_client
  end

  def sync_repository
    # @sync_repository ||= sync_client.find_repository(id: repository.id)
    @sync_repository ||= sync_client.find_repository(id: 2)
  end

  def update_top_container(id:, barcode:, indicator:, location:)
    #absolute_id.locking_user = user
    #absolute_id.save
    #absolute_id.reload

    # Remove this
    #container = sync_repository.find_top_container(id: id)
    container = sync_repository.find_top_container(id: 1)

    current_locations = container.locations

    # Remove this
    location2 = current_locations.first.client.find_location(id: 2)

    diff = [location] - current_locations
    updated_locations = current_locations + diff
    # Remove this
    updated_locations = current_locations + [location2]

    container.update(barcode: barcode.value, indicator: indicator, container_locations: updated_locations)

    #absolute_id.locking_user = nil
    #absolute_id.synchronized = true
    #absolute_id.synchronized_on = DateTime.now
    #absolute_id.save
  end
end
