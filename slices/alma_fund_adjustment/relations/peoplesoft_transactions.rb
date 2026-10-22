# frozen_string_literal: true

module AlmaFundAdjustment
  module Relations
    class PeoplesoftTransactions < Hanami::DB::Relation
      schema :peoplesoft_transactions, infer: true
    end
  end
end
