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

  def self.uncache(resource)
    models = where(uri: resource.uri.to_s)
    models.each do |model|
      model.destroy
    end
    resource
  end

  def self.build_from_resource(resource)
    uri = resource.uri.to_s
    json_resource = JSON.generate(resource.attributes)
    new(uri: uri, json_resource: json_resource)
  end

  def self.cache(resource)
    uncache(resource)

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

  def properties
    {
      create_time: json_object.create_time,
      id: json_object.id,
      system_mtime: json_object.system_mtime,
      uri: uri,
      user_mtime: json_object.user_mtime
    }
  end

  # This can be removed
  def source_client
    @client ||= begin
                  new_client = LibJobs::ArchivesSpace::Client.source
                  new_client.login
                  new_client
                end
  end

  def to_resource
    resource_attributes = properties

    self.class.resource_class.new(resource_attributes)
  end
end
