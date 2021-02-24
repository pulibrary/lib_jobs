class AddUserRefToBatches < ActiveRecord::Migration[5.2]
  def change
    add_reference :absolute_id_batches, :user, foreign_key: true
  end
end
