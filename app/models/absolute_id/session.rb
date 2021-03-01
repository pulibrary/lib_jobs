class AbsoluteId::Session < ApplicationRecord
  include ActiveModel::Serializers::JSON
  has_many :batches, class_name: 'AbsoluteId::Batch'
  belongs_to :user

  def label
    format("Session %d (%s)", id, created_at.strftime('%m/%d/%Y'))
  end

  def attributes
    {
      batches: batches.map(&:attributes)
    }
  end

  def as_json(options = nil)
    JSON.generate(attributes)
  end

  def to_txt
    YAML.dump(attributes)
  end
end
