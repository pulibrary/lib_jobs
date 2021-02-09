# frozen_string_literal: true
class AbsoluteId::Record < ApplicationRecord
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

  def to_resource
    self.class.resource_class.new(attributes)
  end
end
