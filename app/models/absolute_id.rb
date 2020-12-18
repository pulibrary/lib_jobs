# frozen_string_literal: true
class AbsoluteId < ApplicationRecord
  class Barcode
    attr_reader :value

    class InvalidBarcodeError < StandardError; end

    def initialize(value)
      raise InvalidBarcodeError, "Barcode values cannot be nil" if value.nil?

      @value = value
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
      output[0, 13]
    end
  end

  class NokogiriSerializer
    def initialize(model, _options = {})
      @model = model
    end

    def model_element_name
      "<#{@model.model_name.to_s.underscore} />"
    end

    def build_document_tree
      Nokogiri::XML(model_element_name)
    end

    def document_tree
      @document_tree ||= build_document_tree
    end

    def root_element
      @root_element ||= document_tree.root
    end

    def build_element(element_name:, type_attribute:, value:)
      new_element = document_tree.create_element(element_name)
      new_element['type'] = type_attribute

      if value.respond_to?(:each)
        children = value.map { |child_value| build_element(element_name: element_name, type_attribute: type_attribute, value: child_value) }
        node_set = Nokogiri::XML::NodeSet.new(document_tree, children)
        new_element.children = node_set
      else
        new_element.content = value
      end

      new_element
    end

    def build_document
      @document_tree = build_document_tree

      @model.attributes.each_pair do |key, value|
        element_name = key.to_s.underscore
        type_attribute = if value.is_a?(ActiveSupport::TimeWithZone)
                           'time'
                         elsif value.is_a?(TrueClass) || value.is_a?(FalseClass)
                           'boolean'
                         else
                           value.class.to_s.underscore
                         end
        new_element = build_element(element_name: element_name, type_attribute: type_attribute, value: value)

        root_element.add_child(new_element)
      end

      document_tree
    end

    def document
      @document ||= build_document
    end

    def serialize
      document.to_xml
    end
  end

  class BarcodeValidator < ActiveModel::Validator
    def validate(absolute_id)
      return if absolute_id.value.nil?

      unless absolute_id.integer.nil?
        absolute_id.errors.add(:value, "Mismatch between the digit sequence and the ID") if absolute_id.integer != absolute_id.barcode.integer
      end

      if absolute_id.check_digit.nil?

        unless absolute_id.digits.length != 14
          absolute_id.errors.add(:value, "Please use an ID with a sequence of 13 digits and a check digit using the Luhn algorithm (please see: https://github.com/topics/luhn-algorithm?l=ruby)")
        end
        unless absolute_id.barcode.valid?
          absolute_id.errors.add(:check_digit, "Please specify a ID with valid check digit using the Luhn algorithm (please see: https://github.com/topics/luhn-algorithm?l=ruby)")
        end

      elsif absolute_id.digits.length == 14 # check digit exists and value is 14 characters

        unless absolute_id.check_digit == absolute_id.barcode.check_digit
          absolute_id.errors.add(:check_digit, "Please specify a ID with valid check digit using the Luhn algorithm (please see: https://github.com/topics/luhn-algorithm?l=ruby)")
        end

      elsif absolute_id.digits.length == 13 # check digit exists and value is 13 characters

        unless absolute_id.check_digit == absolute_id.barcode.check_digit
          absolute_id.errors.add(:check_digit, "Please specify a ID with valid check digit using the Luhn algorithm (please see: https://github.com/topics/luhn-algorithm?l=ruby)")
        end

      else
        absolute_id.errors.add(:value, "Please use an ID with a sequence of 13 digits")
      end
    end
  end

  validates :value, presence: true
  validates_with BarcodeValidator

  after_validation do
    if value.present?
      parsed_digits = Barcode.parse_digits(value)

      if prefix.present? && parsed_digits.length >= 13 && value.length <= (13 + prefix.length)
        truncated = parsed_digits.reverse[0..12]
        normal = truncated.reverse.map(&:to_s).join
        self.value = "#{prefix}#{normal}"
        parsed_digits = Barcode.parse_digits(value)
      end

      self.integer = barcode.integer if integer.nil?
      self.check_digit = barcode.check_digit if check_digit.nil?

      self.value = "#{value}#{check_digit}" if parsed_digits.length == 13
    end
  end

  def barcode
    Barcode.new(value)
  end
  delegate :digits, :elements, to: :barcode

  def attributes
    {
      check_digit: check_digit,
      created_at: created_at,
      digits: digits,
      integer: integer,
      updated_at: updated_at,
      valid: valid?,
      value: value
    }
  end

  # Not certain why this is happening
  def as_json(**_args)
    attributes
  end

  def self.xml_serializer
    NokogiriSerializer
  end

  def xml_serializer
    self.class.xml_serializer
  end

  # @see ActiveModel::Serializers::Xml
  def to_xml(options = {}, &block)
    xml_serializer.new(self, options).serialize(&block)
  end

  def self.default_prefix
    'A'
  end

  def self.default_initial_integer
    0
  end

  def self.default_initial_value(prefix:)
    format("%s%013d", prefix, default_initial_integer)
  end

  def self.generate(**attributes)
    # @prefix = attributes[:id_prefix] if attributes.key?(:id_prefix)
    prefix = if attributes.key?(:id_prefix)
               attributes[:id_prefix]
             else
               default_prefix
             end

    # @initial_value = attributes[:first_code]
    initial_value = if attributes.key?(:first_code)
                      attributes[:first_code]
                    else
                      default_initial_value(prefix: prefix)
                    end

    generated = where(prefix: prefix, initial_value: initial_value)
    if generated.empty?
      new_barcode = Barcode.new(initial_value)
      new_check_digit = new_barcode.check_digit
      create(prefix: prefix, value: initial_value, check_digit: new_check_digit, initial_value: initial_value)
    else
      last_absolute_id = generated.last
      next_integer = last_absolute_id.integer + 1
      next_value = format("%s%013d", prefix, next_integer)

      new_barcode = Barcode.new(next_value)
      new_check_digit = new_barcode.check_digit
      create(prefix: prefix, value: next_value, check_digit: new_check_digit, initial_value: initial_value)
    end
  end
end
