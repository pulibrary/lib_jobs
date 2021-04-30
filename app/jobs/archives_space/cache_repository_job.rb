# frozen_string_literal: true

module ArchivesSpace
  class CacheRepositoryJob < ApplicationJob
    queue_as :high

    def perform(repository_uri:)
      repository = source_client.find_repository_by(uri: repository_uri)
      Rails.logger.info("Caching repository #{repository.uri}...")

      repository.cache
      Rails.logger.info("Cached repository #{repository.uri}")
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
