class CreateDataSets < ActiveRecord::Migration[5.2]
  def change
    create_table :data_sets do |t|

      t.timestamps
    end
  end
end
