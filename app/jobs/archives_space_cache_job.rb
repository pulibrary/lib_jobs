# frozen_string_literal: true
class ArchivesSpaceCacheJob < ApplicationJob
  queue_as :high

  def perform
    source_client.repositories.each do |repository|
      repository.top_containers.each do |top_container|
        ArchivesSpaceCacheTopContainerJob.perform_later(repository_uri: repository.uri, top_container_uri: top_container.uri)
      end

      ArchivesSpaceCacheRepositoryJob.perform_later(repository_uri: repository.uri)
    end

    source_client.container_profiles.each do |container_profile|
      ArchivesSpaceCacheContainerProfileJob.perform_later(container_profile_uri: container_profile.uri)
    end
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
