# frozen_string_literal: true
module Barcodes
  class CreateBatchJob < AbsoluteIds::CreateBatchJob
    def self.create_model_job
      Barcodes::CreateModelJob
    end
  end
end
