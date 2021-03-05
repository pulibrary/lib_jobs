# frozen_string_literal: true
class ArchivesSpaceCacheJob < ApplicationJob
  queue_as :default

  def perform
    source_client.repositories.each do |repository|
      repository.resources.each do |resource|
        ArchivesSpaceCacheResourceJob.perform_later(repository_uri: repository.uri, resource_uri: resource.uri)
      end
    end
  end

  def perform_foo
    Rails.logger.info("Caching locations...")
    source_client.locations.each do |location|
      location.cache
      Rails.logger.info("Cached location #{location.uri}...")
    end

    Rails.logger.info("Caching container profile...")
    source_client.container_profiles.each do |container_profile|
      container_profile.cache
      Rails.logger.info("Cached container profile #{container_profile.uri}...")
    end

    Rails.logger.info("Caching repositories...")
    source_client.repositories.each do |repository|
      repository.cache
      Rails.logger.info("Cached repository #{repository.uri}...")

      repository.top_containers.each do |top_container|
        top_container.cache
        Rails.logger.info("Cached container #{top_container.uri}...")
      end

      repository.resources.each do |resource|
        resource.cache
        Rails.logger.info("Cached resource #{resource.uri}...")
      end
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
