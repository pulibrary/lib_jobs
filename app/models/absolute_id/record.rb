# frozen_string_literal: true
class AbsoluteId::Record < ApplicationRecord
  self.abstract_class = true

  def self.table_name_prefix
    'absolute_id_'
  end

  def self.find_cached(uri)
    model = find_by(uri: uri)
    return if model.nil?

    model.to_resource
  end

  def self.cached
    models = all
    models.map(&:to_resource)
  end

  def self.cache(resource)
    models = where(uri: resource.uri)
    models.each do |model|
      model.destroy
    end

    new_model = build_from_resource(resource)
    new_model.save
    resource
  end

  def self.uncache(resource)
    models = where(uri: resource.uri)
    models.each do |model|
      model.destroy
    end
  end

  def self.resource_class
    raise NotImplementedError, "#{self} is an abstract base class. Please use a class derived from this one."
  end

  def json_resource
    @json_resource ||= begin
                         json_properties = super
                         properties = JSON.parse(json_properties)
                         OpenStruct.new(properties)
                       end
  end

  def attributes
    {
      create_time: json_resource.create_time,
      id: json_resource.id,
      system_mtime: json_resource.system_mtime,
      uri: uri,
      user_mtime: json_resource.user_mtime
    }
  end

  def to_resource
    self.class.resource_class.new(attributes)
  end
end
