class AbsoluteId::Session < ApplicationRecord
  include ActiveModel::Serializers::JSON
  has_many :absolute_id_batches
  belongs_to :user

  def label
    # format("Session %06d (%s)", id, created_at.strftime('%m/%d/%Y'))
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
end
