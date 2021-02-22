class CreateAbsoluteIdBatches < ActiveRecord::Migration[5.2]
  def change
    create_table :absolute_id_batches do |t|

      t.timestamps
    end
  end
end
