# frozen_string_literal: true
class RecentJobStatus < ApplicationRecord
  include Dry::Monads[:result]
  def self.register(job:, status:)
    # rubocop:disable Rails/SkipsModelValidations
    upsert({ job:, status: case status
                           when Failure then :failure
                           when Success then :success
                           else
                             raise 'You must register Success or Failure'
                           end }, unique_by: :job)
    # rubocop:enable Rails/SkipsModelValidations
  end
end
