# frozen_string_literal: true
class AddASpaceFieldsToAbsoluteIds < ActiveRecord::Migration[5.2]
  def change
    add_column :absolute_ids, :repository_id, :string
    add_column :absolute_ids, :resource_id, :string
  end
end
