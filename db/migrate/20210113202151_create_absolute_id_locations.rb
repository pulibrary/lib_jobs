class CreateAbsoluteIdLocations < ActiveRecord::Migration[5.2]
  def change
    create_table :absolute_id_locations do |t|
      t.string :label
      t.string :value

      t.timestamps
    end
  end
end
