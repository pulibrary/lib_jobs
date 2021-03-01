class AddUnencodedLocationToAbsoluteIds < ActiveRecord::Migration[5.2]
  def change
    add_column :absolute_ids, :unencoded_location, :string
  end
end
