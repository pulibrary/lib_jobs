# frozen_string_literal: true
module PeoplesoftBursar
  class Amount
    attr_reader :patron_id, :item_type, :term_code, :amount, :reversal_indicator, :fine_id, :date, :description

    def initialize(patron_id:, term_code:, amount:, reversal_indicator:, fine_id:, date:, description:) # rubocop:disable Metrics/ParameterLists
      @patron_id = patron_id
      @item_type = '240000012000'
      @term_code = term_code
      @amount = amount
      @reversal_indicator = reversal_indicator
      @fine_id = fine_id.ljust(30)
      @date = date
      @description = description
    end

    def formatted_amount
      @formatted_amount = format('%015.2<amt>f', amt: amount.abs)
    end

    def to_s
      "#{patron_id} #{item_type} #{term_code} #{formatted_amount} #{reversal_indicator} #{fine_id} #{date.strftime('%m%d%y')} #{description}"
    end
  end
end
