# frozen_string_literal: true
class ArchivesSpaceClearCacheJob < ApplicationJob
  queue_as :high

  def perform
    Rails.logger.info("Caching repositories...")
    AbsoluteId::TopContainer.all.map(&:destroy!)

    Rails.logger.info("Caching repositories...")
    AbsoluteId::ArchivalObject.all.map(&:destroy!)

    Rails.logger.info("Caching repositories...")
    AbsoluteId::Resource.all.map(&:destroy!)

    Rails.logger.info("Caching repositories...")
    AbsoluteId::Repository.all.map(&:destroy!)

    Rails.logger.info("Caching container profile...")
    AbsoluteId::ContainerProfile.all.map(&:destroy!)

    Rails.logger.info("Caching locations...")
    AbsoluteId::Location.all.map(&:destroy!)
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
