# frozen_string_literal: true
class AbsoluteId::Batch < ApplicationRecord
  has_many :absolute_ids, foreign_key: "absolute_id_batch_id"
  belongs_to :session, class_name: 'AbsoluteId::Session', foreign_key: "absolute_id_session_id", optional: true
  belongs_to :user, foreign_key: "user_id"

  def self.xml_serializer
    AbsoluteIds::BatchXmlSerializer
  end

  def label
    format("Batch %06d", id)
  end

  def synchronized?
    absolute_ids.map(&:synchronized?).reduce(&:&)
  end

  def synchronizing?
    absolute_ids.map(&:synchronizing?).reduce(&:|)
  end

  def synchronize_status
    values = absolute_ids.map(&:synchronize_status)

    if values.include?(AbsoluteId::SYNCHRONIZE_FAILED)
      AbsoluteId::SYNCHRONIZE_FAILED
    elsif values.include?(AbsoluteId::NEVER_SYNCHRONIZED)
      AbsoluteId::NEVER_SYNCHRONIZED
    elsif values.include?(AbsoluteId::UNSYNCHRONIZED)
      AbsoluteId::UNSYNCHRONIZED
    elsif values.include?(AbsoluteId::SYNCHRONIZING)
      AbsoluteId::SYNCHRONIZING
    else
      AbsoluteId::SYNCHRONIZED
    end
  end

  # Refactor this
  def report_entries
    entries = absolute_ids.map do |absolute_id|
      {
        label: absolute_id.label,
        user: user.email,
        barcode: absolute_id.barcode.value,
        location: absolute_id.location_object,
        container_profile: absolute_id.container_profile_object,
        repository: absolute_id.repository_object,
        resource: absolute_id.resource_object,
        container: absolute_id.container_object,
        status: AbsoluteId::UNSYNCHRONIZED,
        synchronized_at: absolute_id.synchronized_at
      }
    end

    entries.map { |entry| OpenStruct.new(entry) }
  end

  def table_data
    absolute_ids.order(:id).map do |absolute_id|
      {
        label: absolute_id.label,
        user: user.email,
        barcode: absolute_id.barcode.value,
        location: { link: absolute_id.location_object.uri, value: absolute_id.location_object.building },
        container_profile: { link: absolute_id.container_profile_object.uri, value: absolute_id.container_profile_object.name },
        repository: { link: absolute_id.repository_object.uri, value: absolute_id.repository_object.name },
        resource: { link: absolute_id.resource_object.uri, value: absolute_id.resource_object.title },
        container: { link: absolute_id.container_object.uri, value: absolute_id.container_object.indicator },
        status: { value: absolute_id.synchronize_status, color: absolute_id.synchronize_status_color },
        synchronized_at: absolute_id.synchronized_at || 'Never'
      }
    end
  end

  def attributes
    {
      id: id,
      label: label,
      table_data: table_data
    }
  end

  # @see ActiveModel::Serializers::Xml
  def to_xml(options = {}, &block)
    self.class.xml_serializer.new(self, options).serialize(&block)
  end

  # @todo Determine why this is required
  def as_json(**_args)
    attributes
  end
end
