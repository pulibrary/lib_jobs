# frozen_string_literal: true
class AddASpaceFieldsToAbsoluteIds < ActiveRecord::Migration[5.2]
  def change
    add_column :absolute_ids, :location, :string
    add_column :absolute_ids, :container_profile, :string

    add_column :absolute_ids, :repository, :string
    add_column :absolute_ids, :resource, :string
    add_column :absolute_ids, :container, :string
  end
end
