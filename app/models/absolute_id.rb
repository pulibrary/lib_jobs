# frozen_string_literal: true
class AbsoluteId < ApplicationRecord
  NEVER_SYNCHRONIZED = 'never synchronized'
  UNSYNCHRONIZED = 'unsynchronized'
  SYNCHRONIZING = 'synchronizing'
  SYNCHRONIZED = 'synchronized'
  SYNCHRONIZE_FAILED = 'synchronization failed'

  class BarcodeValidator < ActiveModel::Validator
    def validate(absolute_id)
      return if absolute_id.integer.nil?

      absolute_id.errors.add(:value, "Mismatch between the digit sequence and the ID") if absolute_id.integer.to_i != absolute_id.barcode.integer

      ## Disabled until the factories are fixed
      # barcode = AbsoluteIds::Barcode.build(absolute_id.value)
      # return if barcode.check_digit == absolute_id.check_digit

      # absolute_id.errors.add(:check_digit, "Please specify a ID with valid check digit using the Luhn algorithm (please see: https://github.com/topics/luhn-algorithm?l=ruby)")
    end
  end

  class LocatorValidator < ActiveModel::Validator
    def validate(absolute_id)
      return if absolute_id.index.nil?

      ## Disabled until the factories are fixed
      # persisted = AbsoluteId.find_by(index: absolute_id.index, container_profile: absolute_id.container_profile, location: absolute_id.location)
      # return if persisted.nil? || persisted.id == absolute_id.id

      # absolute_id.errors.add(:index, "Duplicate index #{absolute_id.index} for the AbID within the Location #{absolute_id.location} and ContainerProfile #{absolute_id.container_profile}")
    end
  end

  validates :value, presence: true
  ## Disabled until the factories are fixed
  # validates :check_digit, presence: true
  validates_with BarcodeValidator
  validates_with LocatorValidator

  belongs_to :batch, class_name: 'AbsoluteId::Batch', optional: true, foreign_key: "absolute_id_batch_id"

  def self.barcode_class
    AbsoluteIds::Barcode
  end

  def self.default_barcode_value
    format("%014d", 0)
  end

  def self.generate(**attributes)
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
                                          synchronize_status: synchronize_status
                                        })

    create(**model_attributes)
  end

  def self.sizes
    LibJobs.config["sizes"]
  end

  def self.global_prefixes
    sizes["global"]
  end

  def self.local_prefixes
    sizes.select { |k, v| k != "global" && v.is_a?(Hash) }
  end

  def self.prefixes
    local_merged = local_prefixes.to_h.values.inject(:merge)
    global_prefixes.merge(local_merged)
  end

  def self.find_prefix(key)
    prefixes[key]
  end

  def self.find_prefixed_models(prefix:)
    models = all
    models.select do |model|
      model.size == prefix
    end
  end

  def self.xml_serializer
    AbsoluteIds::AbsoluteIdXmlSerializer
  end

  def barcode
    @barcode ||= self.class.barcode_class.new(value)
  end
  delegate :digits, :elements, to: :barcode

  def find_local_prefixes(key)
    self.class.local_prefixes[key]
  end

  def local_prefixes
    @local_prefixes ||= begin
                          if location_object.name
                            find_local_prefixes(location.key)
                          elsif self.class.local_prefixes.key?(location)
                            find_local_prefixes(location)
                          else
                            {}
                          end
                        end
  end

  def prefixes
    @prefixes ||= begin
                    self.class.global_prefixes.merge(local_prefixes)
                  end
  end

  def size
    if container_profile_object.name
      prefixes[container_profile_object.name]
    elsif prefixes.key?(container_profile)
      prefixes[container_profile]
    else
      container_profile
    end
  end
  # @todo Deprecate #prefix in favor of #size
  alias prefix size

  def locator
    return if index.nil? || size.nil?

    format("%s-%06d", size, index)
  end
  # @todo Deprecate #label in favor of #locator
  alias label locator

  def barcode_only?
    barcode.present? && label.blank?
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
      size: size,
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
  rescue JSON::ParserError
    {}
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
    json_attribute(container)
  end
end
