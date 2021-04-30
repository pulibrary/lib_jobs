# frozen_string_literal: true

module ArchivesSpace
  class CacheJob < ApplicationJob
    queue_as :high

    def perform_now
      cache
    end

    def perform
      cache
    end

    private

    def cache
      source_client.repositories.each do |repository|
        repository.resources.each do |resource|
          CacheResourceJob.perform_now(repository_uri: repository.uri, resource_uri: resource.uri)
        end

        repository.top_containers.each do |top_container|
          CacheTopContainerJob.perform_now(repository_uri: repository.uri, top_container_uri: top_container.uri)
        end

        CacheRepositoryJob.perform_now(repository_uri: repository.uri)
      end
    end

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
