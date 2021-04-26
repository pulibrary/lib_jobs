# frozen_string_literal: true
module AbsoluteIds
  class Barcode
    # Luhn algorithm implementation
    # @todo This needs to be fixed
    def self.generate_check_digit(code)
      padded = "#{code}0"
      parity = padded.length % 2
      sum = 0

      code_digits = padded.scan(/\d/).map(&:to_i)
      code_digits.reverse.each_with_index do |digit, index|
        addend = digit

        addend *= 2 if index % 2 == parity
        addend -= 9 if addend > 9

        sum += addend
      end

      remainder = sum % 10
      remainder.zero? ? 0 : 10 - remainder
    end

    attr_reader :value, :check_digit
    def initialize(value)
      raise InvalidBarcodeError, "Barcode values cannot be blank" if value.blank?

      @value = value
    end

    def +(other)
      new_integer = integer + other
      new_value = format("%013d", new_integer)
      @value = new_value
      self
    end

    def digits
      return if elements.empty?

      elements.map(&:to_i)
    end

    # @todo This needs to be fixed
    # This should follow something similar to:
    #   @value.present? && digits.length == 13
    def valid?
      false
    end

    def integer
      output = elements.join.to_s
      output.to_i
    end
    alias to_i integer

    def elements
      return [] if @value.nil?

      output = @value.scan(/\d/)
      output[0, 13]
    end

    def attributes
      {
        check_digit: check_digit,
        digits: digits,
        integer: integer.to_i,
        valid: valid?,
        value: @value
      }
    end
  end
end
