class AddBatchRefToAbsoluteIds < ActiveRecord::Migration[5.2]
  def change
    add_reference :absolute_ids, :absolute_id_batch, foreign_key: true
  end
end
