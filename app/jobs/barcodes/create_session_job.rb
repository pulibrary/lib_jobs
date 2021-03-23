# frozen_string_literal: true
module Barcodes
  class CreateSessionJob < AbsoluteIds::CreateSessionJob
    def self.create_batch_job
      Barcodes::CreateBatchJob
    end
  end
end
