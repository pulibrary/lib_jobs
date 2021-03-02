class AddSynchronizedToAbsoluteIds < ActiveRecord::Migration[5.2]
  def change
    add_column :absolute_ids, :synchronized_at, :datetime
  end
end
