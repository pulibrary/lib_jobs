# frozen_string_literal: true
module AlmaFundAdjustment
  class FundAdjustment
    attr_reader :row, :adjusted_row, :amount_key
    def initialize(row)
      @row = row
      @amount_key = "AMOUNT"
      @adjusted_row = row.deep_dup
      @adjusted_row[amount_key] = transposed_amount
    end

    def unique_id
      "#{row['TRANSACTION_REFERENCE_NUMBER']}-#{row['TRANSACTION_NOTE']}"
    end

    def original_amount
      row[amount_key]
    end

    def transposed_amount
      if BigDecimal(original_amount).positive?
        "-#{original_amount}"
      else
        original_amount.delete("-")
      end
    end
  end
end
