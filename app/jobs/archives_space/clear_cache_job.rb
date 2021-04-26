# frozen_string_literal: true

module ArchivesSpace
  class ClearCacheJob < ApplicationJob
    queue_as :high

    def perform
      Rails.logger.info("Removing the TopContainer ActiveRecord models...")
      AbsoluteId::TopContainer.all.map(&:destroy!)

      Rails.logger.info("Removing the ArchivalObject ActiveRecord models...")
      AbsoluteId::ArchivalObject.all.map(&:destroy!)

      Rails.logger.info("Removing the Resource ActiveRecord models...")
      AbsoluteId::Resource.all.map(&:destroy!)

      Rails.logger.info("Removing the Repository ActiveRecord models...")
      AbsoluteId::Repository.all.map(&:destroy!)

      Rails.logger.info("Removing the ContainerProfile ActiveRecord models...")
      AbsoluteId::ContainerProfile.all.map(&:destroy!)

      Rails.logger.info("Removing the Location ActiveRecord models...")
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
end
