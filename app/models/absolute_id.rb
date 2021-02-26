# frozen_string_literal: true
class AbsoluteId < ApplicationRecord
  belongs_to :batch

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
      updated_at: updated_at
    }
  end

  # Not certain why this is happening
  def as_json(**_args)
    attributes
  end

  def self.xml_serializer
    AbsoluteIds::BarcodeXmlSerializer
  end

  def xml_serializer
    self.class.xml_serializer
  end

  # @see ActiveModel::Serializers::Xml
  def to_xml(options = {}, &block)
    xml_serializer.new(self, options).serialize(&block)
  end

  def self.default_initial_integer
    0
  end

  def self.default_initial_value
    format("%013d", default_initial_integer)
  end

  def self.generate(**attributes)
    container_profile = attributes[:container_profile]
    container = attributes[:container]
    location = attributes[:location]
    repository = attributes[:repository]
    resource = attributes[:resource]
    index = attributes[:index]

    initial_value = if attributes.key?(:barcode)
                      attributes[:barcode]
                    else
                      default_initial_value
                    end
    models = all

    container_profile_resource = container_profile
    container_profile_resource.delete(:create_time)
    container_profile_resource.delete(:system_mtime)
    container_profile_resource.delete(:user_mtime)

    container_resource = JSON.parse(container.to_json)
    container_resource.delete(:create_time)
    container_resource.delete(:system_mtime)
    container_resource.delete(:user_mtime)

    location_resource = JSON.parse(location.to_json)

    repository_resource = JSON.parse(repository.to_json)
    repository_resource.delete(:create_time)
    repository_resource.delete(:system_mtime)
    repository_resource.delete(:user_mtime)

    ead_resource = JSON.parse(resource.to_json)
    ead_resource.delete(:create_time)
    ead_resource.delete(:system_mtime)
    ead_resource.delete(:user_mtime)

    if models.empty?
      new_barcode = self.barcode_model.new(initial_value)
      new_check_digit = new_barcode.check_digit
      index = 0 if index.nil?

      create(
        value: initial_value,
        check_digit: new_check_digit,
        initial_value: initial_value,

        container_profile: container_profile_resource.to_json,
        container: container_resource.to_json,
        location: location_resource.to_json,
        repository: repository_resource.to_json,
        resource: ead_resource.to_json,
        index: index.to_i
      )
    else
      last_absolute_id = models.last
      next_integer = last_absolute_id.integer.to_i + 1
      next_value = format("%013d", next_integer)

      new_barcode = self.barcode_model.new(next_value)
      new_check_digit = new_barcode.check_digit

      if index.nil?

        # Find persisted indices
        persisted = where(location: location_resource.to_json, container_profile: container_profile_resource.to_json)

        #if !persisted.nil?
        if !persisted.empty?
          index = persisted.last.index.to_i + 1
          #index = persisted.index.to_i + 1
        else
          index = 0
        end
      end

      create(
        value: next_value,
        check_digit: new_check_digit,
        initial_value: initial_value,

        container_profile: container_profile_resource.to_json,
        container: container_resource.to_json,
        location: location_resource.to_json,
        repository: repository_resource.to_json,
        resource: ead_resource.to_json,
        index: index.to_i
      )
    end
  end
end
