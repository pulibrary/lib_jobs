# frozen_string_literal: true
class AbsoluteId < ApplicationRecord
  NEVER_SYNCHRONIZED = 'never synchronized'
  UNSYNCHRONIZED = 'unsynchronized'
  SYNCHRONIZING = 'synchronizing'
  SYNCHRONIZED = 'synchronized'
  SYNCHRONIZE_FAILED = 'synchronization failed'

  class BarcodeValidator < ActiveModel::Validator
    def validate(absolute_id)
      unless absolute_id.integer.nil?
        absolute_id.errors.add(:value, "Mismatch between the digit sequence and the ID") if absolute_id.integer.to_i != absolute_id.barcode.integer
      end

      return unless absolute_id.check_digit.nil?

      absolute_id.errors.add(:check_digit, "Please specify a ID with valid check digit using the Luhn algorithm (please see: https://github.com/topics/luhn-algorithm?l=ruby)")
    end
  end

  validates :value, presence: true
  validates_with BarcodeValidator

  belongs_to :batch, class_name: 'AbsoluteId::Batch', optional: true, foreign_key: "absolute_id_batch_id"

  def self.barcode_class
    AbsoluteIds::Barcode
  end

  def self.default_barcode_value
    format("%014d", 0)
  end

  def self.generate(**attributes)
    index = attributes[:index]

    synchronize_status = NEVER_SYNCHRONIZED

    barcode_value = if attributes.key?(:barcode)
                      attributes.delete(:barcode)
                    else
                      default_barcode_value
                    end

    check_digit = barcode_value.last

    model_attributes = attributes.merge({
                                          value: barcode_value,
                                          check_digit: check_digit,
                                          index: index.to_i,
                                          synchronize_status: synchronize_status
                                        })

    create(**model_attributes)
  end

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

  def self.xml_serializer
    AbsoluteIds::AbsoluteIdXmlSerializer
  end

  def barcode
    @barcode ||= self.class.barcode_class.new(value)
  end
  delegate :digits, :elements, to: :barcode

  def prefix
    self.class.find_prefix(container_profile_object)
  end

  def label
    return if location.nil?

    format("%s-%06d", prefix, index)
  end

  # For ASpace Locations
  def location_object
    OpenStruct.new(location_json)
  end

  ## For ASpace ContainerProfiles
  def container_profile_object
    OpenStruct.new(container_profile_json)
  end

  ## For ASpace Repositories
  def repository_object
    OpenStruct.new(repository_json)
  end

  ## For ASpace Resources
  def resource_object
    OpenStruct.new(resource_json)
  end

  ## For ASpace Containers
  def container_object
    OpenStruct.new(container_json)
  end

  def synchronize_status
    value = super
    if value.blank?
      if synchronized_at.blank?
        UNSYNCHRONIZED
      else
        SYNCHRONIZED
      end
    else
      value
    end
  end

  # This is dislay logic - should this be migrated to another Class? A presenter?
  def synchronize_status_color
    case synchronize_status
    when SYNCHRONIZED
      'green'
    when SYNCHRONIZE_FAILED
      'red'
    when SYNCHRONIZING
      'yellow'
    else
      'blue'
    end
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
      synchronize_status: synchronize_status,
      synchronized_at: synchronized_at,
      updated_at: updated_at
    }
  end

  # @todo Determine why this is required
  def as_json(**_args)
    attributes
  end

  # @see ActiveModel::Serializers::Xml
  def to_xml(options = {}, &block)
    self.class.xml_serializer.new(self, options).serialize(&block)
  end

  private

  def json_attribute(value)
    return {} if value.nil?

    output = JSON.parse(value, symbolize_names: true)
    return {} unless output.is_a?(Hash)

    output
  end

  def location_json
    json_attribute(location)
  end

  def container_profile_json
    json_attribute(container_profile)
  end

  def repository_json
    json_attribute(repository)
  end

  def resource_json
    json_attribute(resource)
  end

  def container_json
    json_attribute(container_profile)
  end
end
