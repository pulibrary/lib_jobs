class AddStatusToAbsoluteIds < ActiveRecord::Migration[5.2]
  def change
    add_column :absolute_ids, :synchronize_status, :string
  end
end
