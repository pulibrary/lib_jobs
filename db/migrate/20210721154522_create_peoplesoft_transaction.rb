class CreatePeoplesoftTransaction < ActiveRecord::Migration[5.2]
  def change
    create_table :peoplesoft_transactions do |t|
      t.string :transaction_id

      t.timestamps
    end
  end
end
