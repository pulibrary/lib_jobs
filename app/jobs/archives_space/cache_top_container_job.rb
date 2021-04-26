# frozen_string_literal: true

module ArchivesSpace
  class CacheTopContainerJob < ApplicationJob
    queue_as :high

    def perform(repository_uri:, top_container_uri:)
      repository = source_client.find_repository_by(uri: repository_uri)
      top_container = repository.find_top_container_by(uri: top_container_uri)
      Rails.logger.info("Caching top_container #{top_container.uri}...")
      top_container.cache
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
