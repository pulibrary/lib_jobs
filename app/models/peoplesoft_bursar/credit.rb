# frozen_string_literal: true
module PeoplesoftBursar
  class Credit < Amount
    START_TERM = 1204 ## December 2, 2019 through June 30, 2020
    START_YEAR = 2020

    def initialize(patron_id:, amount:, date:)
      term_code = get_term_code(date) if date.present?

      # credit amounts are considered the reversal of a fine, so they are always negative
      #   The amount will be converted to negative even if it is passed in as a positive number
      negative_amount = amount.abs * -1.0

      super(patron_id: patron_id, term_code: term_code, amount: negative_amount, reversal_indicator: "Y", fine_id: ' ', date: date, description: 'Library Credit')
    end

    private

    # date <Date> or <DateTime>
    def get_term_code(date)
      current_spring = code_for_year(date)
      current_spring + delta_for_month_day(date.month, date.day)
    end

    def delta_for_month_day(month, day)
      return 0 if month < 7

      if month == 12 && day > 1
        10
      else
        8
      end
    end

    def code_for_year(date)
      year_diff = date.year - START_YEAR
      START_TERM + (year_diff * 10)
    end
  end
end
