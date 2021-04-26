# frozen_string_literal: true

module ArchivesSpace
  class CacheResourceJob < ApplicationJob
    queue_as :high

    def perform(repository_uri:, resource_uri:)
      repository = source_client.find_repository_by(uri: repository_uri)
      resource = repository.find_resource_by(uri: resource_uri)
      Rails.logger.info("Caching resource #{resource.uri}...")
      resource.cache
      Rails.logger.info("Cached resource #{resource.uri}")
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
end
