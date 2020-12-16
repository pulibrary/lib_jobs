# frozen_string_literal: true

class AbsoluteId
  class Barcode
    attr_reader :value

    class InvalidBarcodeError < StandardError; end

    def initialize(value)
      @value = value

      # raise InvalidBarcodeError.new(value) unless valid?
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

    def self.generate_check_digit(integer)
      sum = 0
      digits = integer.to_s.chars.map(&:to_i)

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

    private

    def elements
      @value.scan(/\d/)
    end
  end

  delegate :check_digit, :digits, :integer, :to_i, :valid?, :value, to: :@barcode

  @cache = {}

  def initialize(barcode: nil)
    @barcode = barcode
  end

  def attributes
    {
      check_digit: check_digit,
      digits: digits,
      integer: integer,
      valid: valid?,
      value: value
    }
  end

  def as_json(**_opts)
    attributes
  end

  def self.cache(barcode)
    @cache[barcode.value] = barcode
  end

  def self.delete(barcode)
    @cache.delete(barcode.value)
  end

  def self.find(value)
    @cache[value]
  end

  def save
    self.class.cache(self)
  end

  def delete
    self.class.delete(self)
  end

  def self.all
    @cache.values
  end

  def self.last
    all.last
  end

  def self.build_codabar(unencoded)
    Barcode.new(unencoded)
  end

  def self.initial_unencoded_number
    0
  end

  def self.first_encoded_value
    format("%013d", initial_unencoded_number)
  end

  def self.next_encoded_value
    last_absolute_id = last

    last_integer = last_absolute_id.value[0..-1]
    barcode_value = last_integer.to_i + 1
    format("%013d", barcode_value)
  end

  def self.build(**_args)
    encoded_value = if all.empty?
                      first_encoded_value
                    else
                      next_encoded_value
                    end

    new_barcode = Barcode.build(encoded_value)
    new(barcode: new_barcode)
  end

  def self.create(**args)
    new_absolute_id = build(**args)
    new_absolute_id.save
  end
end
