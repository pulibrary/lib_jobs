# frozen_string_literal: true
class AddFormFieldsToAbsoluteIds < ActiveRecord::Migration[5.2]
  def change
    add_column :absolute_ids, :prefix, :string
    add_column :absolute_ids, :initial_value, :string
  end
end
