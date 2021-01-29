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
      output[0, 14]
    end

    def attributes
      {
        check_digit: check_digit,
        digits: digits,
        integer: integer,
        valid: valid?,
        value: @value
      }
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
      new_element['type'] = type_attribute unless type_attribute.nil?

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
        type_attribute = if value.is_a?(TrueClass) || value.is_a?(FalseClass)
                           'boolean'
                         elsif value.is_a?(NilClass)
                           nil
                         elsif value.is_a?(ActiveSupport::TimeWithZone)
                           'time'
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

      ## if prefix.present? && parsed_digits.length >= 13 && value.length <= (13 + prefix.length)
      #if parsed_digits.length >= 13 && value.length <= (13 + prefix.length)
      #  truncated = parsed_digits.reverse[0..12]
      #  normal = truncated.reverse.map(&:to_s).join
      #  self.value = "#{prefix}#{normal}"
      #  parsed_digits = Barcode.parse_digits(value)
      #end

      self.integer = barcode.integer if integer.nil?
      self.check_digit = barcode.check_digit if check_digit.nil?

      self.value = "#{value}#{check_digit}" if parsed_digits.length == 13
    end
  end

  def barcode
    @barcode ||= Barcode.new(value)
  end
  delegate :digits, :elements, to: :barcode

  def location
    return if super.nil?

    values = JSON.parse(super, symbolize_names: true)
    OpenStruct.new(values)
  end

  def repository
    return if super.nil?

    values = JSON.parse(super, symbolize_names: true)
    OpenStruct.new(values)
  end

  def resource
    return if super.nil?

    values = JSON.parse(super, symbolize_names: true)
    OpenStruct.new(values)
  end

  def self.prefixes
    {
      'mudd' => 'S',
      'mudd1' => 'D',
      'mudd2' => 'DO',
      'mudd3' => 'L',
      'mudd4' => 'LO',
      'mudd5' => 'XH',
      'mudd6' => 'XH',
      'mss' => 'M'
    }
  end

  def prefix
    self.class.prefixes[container_profile.name]
  end

  def self.find_prefixed_models(prefix:)
    models = all
    models.select do |model|
      model.prefix == prefix
    end
  end

  def index
    # id - self.class.all.first.id
    models = self.class.find_prefixed_models(prefix: prefix)
    models.index { |m| m.id == id }
  end

  def label
    return if location.nil?

    format("%s-%06d", prefix, index)
  end

  def container_profile
    return if super.nil?

    values = JSON.parse(super, symbolize_names: true)
    OpenStruct.new(values)
  end

  def container
    return if super.nil?

    values = JSON.parse(super, symbolize_names: true)
    OpenStruct.new(values)
  end

  def attributes
    {
      barcode: barcode.attributes,
      container: container.to_h,
      container_profile: container_profile.to_h,
      created_at: created_at,
      id: index,
      label: label,
      location: location.to_h,
      prefix: prefix,
      repository: repository.to_h,
      resource: resource.to_h,
      updated_at: updated_at
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

  #def self.default_prefix
  #  'A'
  #end

  def self.default_initial_integer
    0
  end

  # def self.default_initial_value(prefix:)
  def self.default_initial_value
    # format("%s%013d", prefix, default_initial_integer)
    format("%013d", default_initial_integer)
  end

  # @param [Hash] attributes
  # @option opts [Hash] :container_profile
  # @option opts [String] :container_uri
  # @option opts [String] :location_uri
  # @option opts [String] :repository_uri
  # @option opts [String] :resource_uri
  # @option opts [String] :barcode
  def self.generate(**attributes)

=begin
container_profile_uri: "http://localhost:8089/container_profiles/1"
container_uri: "http://localhost:8089/repositories/2/top_containers/1"
location_uri: "http://localhost:8089/locations/1"
repository_uri: "http://localhost:8089/repositories/2"
resource_uri: "http://localhost:8089/repositories/2/resources/1"
=end

    container_profile = attributes[:container_profile]
    #container_profile = JSON.parse(container_profile_values, symbolize_names: true)
    #prefix = container_profile[:name]
    prefix = self.prefixes[container_profile[:name]]

    container = attributes[:container]
    # container = JSON.parse(container_values, symbolize_names: true)

    # location_uri = attributes[:location_uri]
    location = attributes[:location]
    # location = JSON.parse(location_values, symbolize_names: true)

    # repository_uri = attributes[:repository_uri]
    repository = attributes[:repository]
    # repository = JSON.parse(repository_values, symbolize_names: true)

    # resource_uri = attributes[:resource_uri]
    resource = attributes[:resource]
    # resource = JSON.parse(resource_values, symbolize_names: true)

    initial_value = if attributes.key?(:barcode)
                      attributes[:barcode]
                    else
                      # default_initial_value(prefix: prefix)
                      default_initial_value
                    end

    #models = where(initial_value: initial_value)
    #generated = models.select do |model|
    #  prefix == model.prefix
    #end
    models = all

    if models.empty?
      new_barcode = Barcode.new(initial_value)
      new_check_digit = new_barcode.check_digit

      create(
        value: initial_value,
        check_digit: new_check_digit,
        initial_value: initial_value,

        container_profile: container_profile.to_json,
        container: container.to_json,
        location: location.to_json,
        repository: repository.to_json,
        resource: resource.to_json
      )
    else
      last_absolute_id = models.last
      next_integer = last_absolute_id.integer + 1
      # next_value = format("%s%013d", prefix, next_integer)
      next_value = format("%013d", next_integer)

      new_barcode = Barcode.new(next_value)
      new_check_digit = new_barcode.check_digit

      create(
        value: next_value,
        check_digit: new_check_digit,
        initial_value: initial_value,

        container_profile: container_profile.to_json,
        container: container.to_json,
        location: location.to_json,
        repository: repository.to_json,
        resource: resource.to_json
      )
    end
  end
end