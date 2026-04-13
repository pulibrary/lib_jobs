class CreateNextDateToProcess < ActiveRecord::Migration[8.1]
  def change
    create_table :next_date_to_process do |t|
      t.string :job, null: false
      t.date :next, null: false

      t.index :job, unique: true

      t.timestamps
    end
  end
end
