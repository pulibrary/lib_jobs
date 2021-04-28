class AddUnencodedContainerProfileToAbsoluteIds < ActiveRecord::Migration[5.2]
  def change
    add_column :absolute_ids, :unencoded_container_profile, :string
  end
end
