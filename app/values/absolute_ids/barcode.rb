# frozen_string_literal: true
module AbsoluteIds
  class Barcode
    attr_reader :value, :check_digit

    def initialize(value)
      raise InvalidBarcodeError, "Barcode values cannot be nil" if value.nil?

      @value = value
    end

    def +(addend)
      new_integer = integer + addend
      new_value = format("%013d", new_integer)
      @value = new_value
      self
    end

    def check_digit=(new_check_digit)
      current_digits = if @check_digit.nil?
                         digits
                       else
                         digits[0..-1]
                       end

      @check_digit = new_check_digit

      new_digits = current_digits + [new_check_digit]
      new_value = new_digits.map(&:to_s).join
      @value = new_value
    end

    def valid?
      @value.present? && digits.length == 13
    end

    def digits
      return if elements.empty?

      elements.map(&:to_i)
    end

    def integer
      output = elements.join.to_s
      output.to_i
    end
    alias to_i integer

    def self.parse_digits(code)
      parsed = code.scan(/\d/)
      parsed.map(&:to_i)
    end

    # Luhn algorithm implementation
    # Disabled for now
    def self.generate_check_digit(code)
      padded = "#{code}0"
      parity = padded.length % 2
      sum = 0

      code_digits = padded.scan(/\d/).map(&:to_i)
      puts padded
      #puts code_digits
      code_digits.reverse.each_with_index do |digit, index|
        puts digit
        addend = digit

        if index % 2 == parity
          addend *= 2
        end

        if addend > 9
          addend -= 9
        end
        #puts addend

        sum += addend
      end
      puts sum

      remainder = sum % 10
      remainder.zero? ? 0 : 10 - remainder
    end

    def self.build(code)
      value = code[0..13]
      built = new(value)
      built.check_digit = code.last
      built
    end

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
