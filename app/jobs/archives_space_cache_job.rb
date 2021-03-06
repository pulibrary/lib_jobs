# frozen_string_literal: true
class ArchivesSpaceCacheJob < ApplicationJob
  queue_as :high

  def perform
    source_client.repositories.each do |repository|
      repository.resources.each do |resource|
        ArchivesSpaceCacheResourceJob.perform_later(repository_uri: repository.uri, resource_uri: resource.uri)
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
