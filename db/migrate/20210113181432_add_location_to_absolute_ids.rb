class AddLocationToAbsoluteIds < ActiveRecord::Migration[5.2]
  def change
    add_reference :absolute_ids, :location, foreign_key: true
  end
end
