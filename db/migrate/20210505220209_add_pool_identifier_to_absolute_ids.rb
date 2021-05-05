class AddPoolIdentifierToAbsoluteIds < ActiveRecord::Migration[5.2]
  def change
    add_column :absolute_ids, :pool_identifier, :string
    add_index :absolute_ids, :pool_identifier
  end
end
