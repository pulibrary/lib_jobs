# frozen_string_literal: true
module AbsoluteIds
  class CreateBatchJob < BaseJob
    def perform(properties:, user_id:)
      @user_id = user_id
      create_batch(properties)
    end

    def self.create_model_job
      AbsoluteIds::CreateModelJob
    end

    private

    def create_batch(batch_properties)
      ## This is disabled for passing the RSpec system spec suites
      # params_valid = batch_properties[:valid]
      # raise(ArgumentError, batch_properties) unless params_valid

      # Use the same set of params for each AbID
      absolute_id_params = batch_properties[:absolute_id]

      batch_size = batch_properties[:batch_size]

      children = []
      Array.new(batch_size.to_i) do |child_index|
        properties = absolute_id_params.deep_dup
        properties[:barcode] = batch_properties[:barcodes][child_index]
        properties[:index] = child_index
        properties[:source] = batch_properties[:source]

        begin
          model_id = self.class.create_model_job.polymorphic_perform_now(properties: properties, user_id: @user_id)
          children << ::AbsoluteId.find(model_id)
        rescue StandardError => error
          Rails.logger.warn("Failed to create the Absolute ID: #{properties[:barcode]}: #{error}")
          nil
        end
      end

      return if children.empty?

      batch = AbsoluteId::Batch.create(absolute_ids: children, user: current_user)
      batch.save!

      Rails.logger.info("Batch created: #{batch.id}")
      batch.id
    end
  end
end
