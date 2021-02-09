class CreateAbsoluteIdLocations < ActiveRecord::Migration[5.2]
  def change
    create_table :absolute_id_locations do |t|
      t.string :uri
      t.string :json_resource

      t.timestamps
    end
  end
end
