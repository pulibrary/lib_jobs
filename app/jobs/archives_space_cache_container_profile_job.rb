# frozen_string_literal: true
class ArchivesSpaceCacheContainerProfileJob < ApplicationJob
  queue_as :high

  def perform(container_profile_uri:)
    container_profile = source_client.find_container_profile_by(uri: container_profile_uri)
    Rails.logger.info("Caching location #{container_profile.uri}...")
    container_profile.cache
    Rails.logger.info("Cached location #{container_profile.uri}")
  end

  private

  def source_client
    @source_client ||= begin
                         source_client = LibJobs::ArchivesSpace::Client.source
                         Rails.logger.info("Authenticating...")
                         source_client.login
                         Rails.logger.info("Authenticated")
                         source_client
                       end
  end
end
