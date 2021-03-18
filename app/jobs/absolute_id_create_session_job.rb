# frozen_string_literal: true
class AbsoluteIdCreateSessionJob < ApplicationJob
  def perform(session_attributes:, user_id:)
    @user_id = user_id
    create_session(session_attributes)
  end

  private

  def create_session(session_attributes)
    @batches = []
    session_attributes.each do |batch_params|
      model_id = AbsoluteIdCreateBatchJob.perform_now(properties: batch_params.deep_symbolize_keys, user_id: @user_id)
      @batches << AbsoluteId::Batch.find(model_id) unless model_id.nil?
    end

    return if @batches.empty?

    @session = AbsoluteId::Session.create(batches: @batches, user: current_user)
    @session.save!
    Rails.logger.info("Session created: #{@session.id}")
    @session.id
  end

  def current_user
    @current_user ||= User.find_by(id: @user_id)
  end
end
