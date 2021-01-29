# frozen_string_literal: true
class AbsoluteId::Location < ApplicationRecord
  def self.table_name_prefix
    'absolute_id_'
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

  class Configuration < OpenStruct
    def self.default_file_path
      Rails.root.join('config', 'locations.yml')
    end

    def self.default_values
      file_content = IO.read(default_file_path)
      parsed = ERB.new(file_content)
      parsed.result(binding)
    end

    def self.build
      parsed = YAML.safe_load(default_values)
      new(parsed)
    rescue => e
      nil
    end
  end

  def self.configuration
    @configuration ||= Configuration.build
  end

  def self.create_configured
    models = []
    configuration.each_pair do |key, entries|
      entries.each do |entry|
        built = find_or_create_by(**entry.symbolize_keys)
        models << built
      end
    end

    models
  end

  class ValueValidator < ActiveModel::Validator
    def validate(location)
      location.class.configured_values.include?(location.value)
    end
  end

  validates :label, presence: true
  validates :value, presence: true
  # validates_with ValueValidator

  def attributes
    {
      label: label,
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
end