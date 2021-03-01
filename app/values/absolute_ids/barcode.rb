# frozen_string_literal: true
module AbsoluteIds
  class Barcode
    attr_reader :value

    def initialize(value)
      raise InvalidBarcodeError, "Barcode values cannot be nil" if value.nil?

      @value = value
    end

    def +(addend)
      new_integer = integer + addend
      new_value = format("%013d", new_integer)
      @value = new_value

      new_check_digit = self.class.generate_check_digit(@value)
      @check_digit = new_check_digit

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
      return false if @value.blank?
      return false unless digits.length == 14

      segment = value[-1, 1]
      digit = segment.to_i
      digit == check_digit
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

    def check_digit
      @check_digit ||= self.class.generate_check_digit(@value)
    end

    def self.parse_digits(code)
      parsed = code.scan(/\d/)
      parsed.map(&:to_i)
    end

    def self.generate_check_digit(code)
      sum = 0

      parsed = parse_digits(code)
      digits = parsed[0, 13]
      digits.each_with_index do |digit, index|
        addend = digit

        if index.odd?
          addend *= 2
          addend -= 9 if addend > 9
        end

        sum += addend
      end

      remainder = sum % 10
      remainder.zero? ? 0 : 10 - remainder
    end

    def self.build(integer)
      check_digit = generate_check_digit(integer)
      built = new(integer)
      built.check_digit = check_digit
      built
    end

    def elements
      return [] if @value.nil?

      output = @value.scan(/\d/)
      #output[0, 14]
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
