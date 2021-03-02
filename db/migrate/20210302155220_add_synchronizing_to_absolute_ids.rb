class AddSynchronizingToAbsoluteIds < ActiveRecord::Migration[5.2]
  def change
    add_column :absolute_ids, :synchronizing, :boolean
  end
end
