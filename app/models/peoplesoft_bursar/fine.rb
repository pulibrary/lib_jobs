# frozen_string_literal: true
module PeoplesoftBursar
  class Fine < Amount
    def initialize(patron_id:, amount:, date:, fine_id:, fine_type:)
      super(patron_id:, term_code: '    ', amount:, reversal_indicator: "N", fine_id:, date:, description: fine_type)
    end
  end
end
