# frozen_string_literal: true
class AbsoluteIdCreateBatchJob < ApplicationJob
  def perform(properties:, user_id:)
    @user_id = user_id
    create_batch(properties)
  end

  private

  def create_batch(batch_properties)
    batch_size = batch_properties[:batch_size]
    params_valid = batch_properties[:valid]
    raise ArgumentError unless params_valid

    # Use the same set of params for each AbID
    absolute_id_params = batch_properties[:absolute_id]

    children = []
    Array.new(batch_size.to_i) do |child_index|
      properties = absolute_id_params.deep_dup
      properties[:barcode] = batch_properties[:barcodes][child_index]
      properties[:index] = child_index

      begin
        model_id = AbsoluteIdCreateRecordJob.polymorphic_perform_now(properties: properties, user_id: @user_id)
        children << AbsoluteId.find(model_id)
      rescue StandardError => error
        Rails.logger.warn("Failed to create the Absolute ID: #{properties['initial_value']}: #{error}")
        nil
      end
    end

    return if children.empty?

    batch = AbsoluteId::Batch.create(absolute_ids: children, user: current_user)
    batch.save!
    Rails.logger.info("Batch created: #{batch.id}")
    batch.id
  end

  def current_user
    @current_user ||= User.find_by(id: @user_id)
  end
end
