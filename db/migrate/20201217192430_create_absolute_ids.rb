class CreateAbsoluteIds < ActiveRecord::Migration[5.2]
  def change
    create_table :absolute_ids do |t|
      t.string :value
      t.integer :integer
      t.integer :check_digit

      t.timestamps
    end
  end
end
