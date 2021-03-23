# frozen_string_literal: true
module Barcodes
  class CreateModelFromMarcJob < CreateModelJob
    def perform(properties:, user_id:)
      @user_id = user_id

      model_attributes = properties.deep_dup
      create_absolute_id(**model_attributes)
    end
  end
end
