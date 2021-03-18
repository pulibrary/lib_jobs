# frozen_string_literal: true
class AbsoluteId::Record < ApplicationRecord
  self.abstract_class = true
  @cached = false

  def self.table_name_prefix
    'absolute_id_'
  end

  def self.cached?
    @cached
  end

  def self.find_cached(uri)
    model = find_by(uri: uri)
    return if model.nil?

    @cached = true
    model.to_resource
  end

  def self.cached
    models = all
    models.map(&:to_resource)
  end

  def self.uncache(resource)
    models = where(uri: resource.uri.to_s)
    models.each(&:destroy)
    @cached = false unless models.empty?
    resource
  end

  def self.build_from_resource(resource)
    uri = resource.uri.to_s
    json_resource = JSON.generate(resource.attributes)
    new(uri: uri, json_resource: json_resource)
  end

  def self.cache(resource)
    return resource if cached?

    new_model = build_from_resource(resource)
    new_model.save
    resource
  end

  def self.resource_class
    raise NotImplementedError, "#{self} is an abstract base class. Please use a class derived from this one."
  end

  def json_object
    @json_object ||= begin
                       json_properties = json_resource
                       properties = JSON.parse(json_properties)
                       OpenStruct.new(properties)
                     end
  end

  # This is what gets serialized into the model
  # This should match what is in self.class.resource_class#attributes
  def json_properties
    {
      create_time: json_object.create_time,
      id: json_object.id,
      lock_version: json_object.lock_version,
      system_mtime: json_object.system_mtime,
      uri: uri,
      user_mtime: json_object.user_mtime
    }
  end

  def to_resource
    self.class.resource_class.new(json_properties)
  end
end
