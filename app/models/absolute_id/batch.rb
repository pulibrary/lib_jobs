class AbsoluteId::Batch < ApplicationRecord
  include ActiveModel::Serializers::JSON
  has_many :absolute_ids
  belongs_to :session, class_name: 'AbsoluteId::Session', optional: true
  belongs_to :user

  def label
    # format("Batch %06d (%s)", id, created_at.strftime('%m/%d/%Y'))
    format("Batch %06d", id)
  end

  def table_data
    absolute_ids.map do |absolute_id|
      {
        user: user.email,
        barcode: absolute_id.barcode.value,
        label: absolute_id.label,
        location: { link: absolute_id.location_object.uri, value: absolute_id.location_object.building },
        container_profile: { link: absolute_id.container_profile_object.uri, value: absolute_id.container_profile_object.name },
        repository: { link: absolute_id.repository_object.uri, value: absolute_id.repository_object.name },
        resource: { link: absolute_id.resource_object.uri, value: absolute_id.resource_object.title },
        container: { link: absolute_id.container_object.uri, value: absolute_id.container_object.indicator }
      }
    end
  end

  def attributes
    {
      id: id,
      label: label,
      tableData: table_data
    }
  end

  def as_json(options = nil)
    JSON.generate(attributes)
  end
end
