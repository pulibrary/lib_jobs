# frozen_string_literal: true
module AlmaFundAdjustment
  class FundAdjustment
    def call(row)
      adjusted_row = row.deep_dup
      adjusted_row[amount_key] = transposed_amount(row)
      FundAdjustmentResult.new(
        adjusted_row:,
        unique_id: unique_id(row),
        original_amount: original_amount(row),
        transposed_amount: transposed_amount(row)
      )
    end

    def unique_id(row)
      "#{row['TRANSACTION_REFERENCE_NUMBER']}-#{row['TRANSACTION_NOTE']}"
    end

    private

    def amount_key = 'AMOUNT'
    def original_amount(row) = row[amount_key]

    def transposed_amount(row)
      if BigDecimal(original_amount(row)).positive?
        "-#{original_amount(row)}"
      else
        original_amount(row).delete("-")
      end
    end

    FundAdjustmentResult = Data.define(:adjusted_row, :unique_id, :original_amount, :transposed_amount)
  end
end
