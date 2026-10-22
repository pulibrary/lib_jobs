# frozen_string_literal: true

module AlmaFundAdjustment
  module Repos
    class PeoplesoftTransactionsRepo < Hanami::DB::Repo[:peoplesoft_transactions]
      commands :create,
               use: :timestamps,
               plugins_options: { timestamps: { timestamps: [:created_at, :updated_at] } }

      def exists?(transaction_id:)
        !peoplesoft_transactions.where(transaction_id: transaction_id).first.nil?
      end
    end
  end
end
