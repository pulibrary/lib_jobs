# frozen_string_literal: true
# This class is responsible for keeping track of the next
# date that you should process something
class NextDateToProcess < ApplicationRecord
  extend Dry::Monads[:maybe]

  self.table_name = 'next_date_to_process'

  def self.next(job)
    Maybe(find_by(job:)).fmap { it.next }
  end

  def self.set(job:, next:)
    existing = find_by(job:)
    if existing
      Success(existing.update(job:, next:))
    else
      Success(create(job:, next:))
    end
  end
end
