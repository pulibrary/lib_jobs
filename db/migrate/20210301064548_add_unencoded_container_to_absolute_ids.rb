class AddUnencodedContainerToAbsoluteIds < ActiveRecord::Migration[5.2]
  def change
    add_column :absolute_ids, :unencoded_container, :string
  end
end
