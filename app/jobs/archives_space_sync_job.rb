# frozen_string_literal: true
class ArchivesSpaceSyncJob < ApplicationJob
  queue_as :default

  def perform(user_id:, absolute_id:, repository_id:)
    @user_id = user_id
    @absolute_id = absolute_id
    @repository_id = repository_id
  end

  private

  def user
    @user ||= User.find(user_id)
  end
  delegate :aspace_client, to: :user

  def absolute_id
    @absolute_id ||= AbsoluteId.find_by(value: absolute_id)
  end

  def resource_response
    @resource_response ||= begin
                             aspace_client.get("repositories/#{repository_id}")
                           end
  end
end
