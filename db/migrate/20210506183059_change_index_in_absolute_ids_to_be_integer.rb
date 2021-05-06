# frozen_string_literal: true

class ChangeIndexInAbsoluteIdsToBeInteger < ActiveRecord::Migration[5.2]
  def up
    change_column :absolute_ids, :index, 'integer USING CAST(index AS integer)'
  end

  def down
    change_column :absolute_ids, :index, :string
  end
end
