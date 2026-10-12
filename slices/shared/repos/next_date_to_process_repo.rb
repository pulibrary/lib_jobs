# frozen_string_literal: true

module Shared
  module Repos
    class NextDateToProcessRepo < Hanami::DB::Repo[:next_date_to_process]
      include Dry::Monads[:maybe, :result]

      def all = next_date_to_process.to_a

      commands :create,
               use: :timestamps,
               plugins_options: { timestamps: { timestamps: [:created_at, :updated_at] } }

      commands update: :by_pk,
               use: :timestamps,
               plugins_options: { timestamps: { timestamps: [:updated_at] } }

      def next(job:) = Maybe(next_date_to_process.where(job:).first).fmap(&:next)

      def set(job:, next:)
        existing = next_date_to_process.where(job:)
        case existing.count
        when 0
          Success(
            create(job:, next:)
          )
        when 1
          Success(
            existing.command(:update).call(next:)
          )
        else
          Failure('multiple jobs matched -- these should be unique')
        end
      end
    end
  end
end
