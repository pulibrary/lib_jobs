# frozen_string_literal: true
module Barcodes
  class CreateModelFromAspaceJob < AbsoluteIds::CreateModelFromAspaceJob
    def perform(properties:, user_id:)
      @user_id = user_id

      model_attributes = build_model_attributes(**properties.deep_dup)
      model_attributes[:index] = build_model_index(**model_attributes)
      create_absolute_id(**model_attributes)
    end
  end
end
