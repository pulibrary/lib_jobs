# frozen_string_literal: true
class CreateUsers < ActiveRecord::Migration[5.2]
  def change
    create_table :users do |t|
      t.string :email
      t.string :token

      t.timestamps
    end
  end
end
