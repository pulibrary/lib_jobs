# frozen_string_literal: true
class ArchivesSpaceCacheLocationJob < ApplicationJob
  queue_as :high

  def perform(location_uri:)
    location = source_client.find_location_by(uri: location_uri)
    Rails.logger.info("Caching location #{location.uri}...")
    location.cache
    Rails.logger.info("Cached location #{location.uri}")
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
