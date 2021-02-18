class AddStatusToDataSet < ActiveRecord::Migration[5.2]
  def change
    add_column :data_sets, :status, :boolean, :default => true
  end
end
