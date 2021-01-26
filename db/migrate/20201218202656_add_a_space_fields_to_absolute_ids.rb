# frozen_string_literal: true
class AddASpaceFieldsToAbsoluteIds < ActiveRecord::Migration[5.2]
  def change
    add_column :absolute_ids, :repository_uri, :string
    add_column :absolute_ids, :resource_uri, :string
  end
end
