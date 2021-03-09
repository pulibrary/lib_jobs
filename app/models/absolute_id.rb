# frozen_string_literal: true
class AbsoluteId < ApplicationRecord
  belongs_to :batch, class_name: 'AbsoluteId::Batch', optional: true

  def self.barcode_model
    AbsoluteIds::Barcode
  end

  class BarcodeValidator < ActiveModel::Validator
    def validate(absolute_id)
      return if absolute_id.value.nil?

      unless absolute_id.integer.nil?
        absolute_id.errors.add(:value, "Mismatch between the digit sequence and the ID") if absolute_id.integer.to_i != absolute_id.barcode.integer
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
      parsed_digits = self.class.barcode_model.parse_digits(value)

      self.integer = barcode.integer.to_s if integer.nil?
      self.check_digit = barcode.check_digit if check_digit.nil?

      self.value = "#{value}#{check_digit}" if parsed_digits.length == 13
    end
  end

  def barcode
    @barcode ||= self.class.barcode_model.new(value)
  end
  delegate :digits, :elements, to: :barcode

  def self.prefixes
    {
      'Objects' => 'C',

      'BoxQ' => 'L',
      'Double Elephant size box' => 'Z',
      'Double Elephant volume' => 'D',
      'Elephant size box' => 'P',
      'Elephant volume' => 'E',
      'Folio' => 'F',

      'Mudd OS depth' => 'DO',
      'Mudd OS height' => 'H',
      'Mudd OS length' => 'LO',
      'Mudd ST records center' => 'S',
      'Mudd ST manuscript' => 'S',
      'Mudd ST half-manuscript' => 'S',
      'Mudd ST other' => 'S',
      'Mudd OS open' => 'O',

      'NBox' => 'B',
      'Ordinary' => 'N',
      'Quarto' => 'Q',
      'Small' => 'S'
    }
  end

  def self.default_prefix
    'C'
  end

  def self.find_prefix(container_profile)
    return default_prefix unless prefixes.key?(container_profile.name)

    prefixes[container_profile.name]
  end

  def self.find_prefixed_models(prefix:)
    models = all
    models.select do |model|
      model.prefix == prefix
    end
  end

  def prefix
    self.class.find_prefix(container_profile_object)
  end

  def label
    return if location.nil?

    format("%s-%06d", prefix, index)
  end

  def location_object
    return if location.nil?

    values = JSON.parse(location, symbolize_names: true)
    OpenStruct.new(values)
  end

  def repository_object
    return if repository.nil?

    values = JSON.parse(repository, symbolize_names: true)
    OpenStruct.new(values)
  end

  def resource_object
    return if resource.nil?

    values = JSON.parse(resource, symbolize_names: true)
    OpenStruct.new(values)
  end

  def container_profile_object
    return if container_profile.nil?

    values = JSON.parse(container_profile, symbolize_names: true)
    OpenStruct.new(values)
  end

  def container_object
    return if container.nil?

    values = JSON.parse(container, symbolize_names: true)
    OpenStruct.new(values)
  end

  def synchronized?
    !synchronized_at.nil?
  end

  def synchronizing?
    !synchronizing.nil? && synchronizing
  end

  def attributes
    {
      barcode: barcode.attributes,
      container: container_object.to_h,
      container_profile: container_profile_object.to_h,
      created_at: created_at,
      id: index.to_i,
      label: label,
      location: location_object.to_h,
      prefix: prefix,
      repository: repository_object.to_h,
      resource: resource_object.to_h,
      synchronized_at: synchronized_at,
      synchronizing: synchronizing,
      updated_at: updated_at
    }
  end

  # Not certain why this is happening
  def as_json(**_args)
    attributes
  end

  def self.xml_serializer
    AbsoluteIds::AbsoluteIdXmlSerializer
  end

  # @see ActiveModel::Serializers::Xml
  def to_xml(options = {}, &block)
    self.class.xml_serializer.new(self, options).serialize(&block)
  end

  def self.default_initial_integer
    0
  end

  def self.default_initial_value
    format("%013d", default_initial_integer)
  end

  def self.generate(**attributes)
    container_profile_resource = attributes[:container_profile]
    container_resource = attributes[:container]
    location_resource = attributes[:location]
    repository_resource = attributes[:repository]
    ead_resource = attributes[:resource]
    index = attributes[:index]

    initial_value = if attributes.key?(:barcode)
                      attributes[:barcode]
                    else
                      default_initial_value
                    end

    #new_barcode = self.barcode_model.new(initial_value)
    #new_check_digit = new_barcode.check_digit
    check_digit = initial_value.last

    model_attributes = {
      value: initial_value,
      check_digit: check_digit,
      initial_value: initial_value,

      container_profile: container_profile_resource.to_json,
      container: container_resource.to_json,
      resource: ead_resource.to_json,
      index: index.to_i
    }

    if attributes.key(:unencoded_location)
      model_attributes[:unencoded_location] = attributes[:unencoded_location]
    else
      model_attributes[:location] = location_resource.to_json
    end

    if attributes.key(:unencoded_repository)
      model_attributes[:unencoded_repository] = attributes[:unencoded_repository]
    else
      model_attributes[:repository] = repository_resource.to_json
    end

    create(**model_attributes)
  end
end
