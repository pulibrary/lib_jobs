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
    end
  end
end
