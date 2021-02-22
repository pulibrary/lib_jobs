class AbsoluteId::Batch < ApplicationRecord
  has_many :absolute_ids
  #belongs_to :user
end
