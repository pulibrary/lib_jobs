class AddFieldsToDataset < ActiveRecord::Migration[5.2]
  def change
    add_column :data_sets, :report_time, :datetime
    add_column :data_sets, :data, :string
    add_column :data_sets, :data_file, :string
    add_column :data_sets, :category, :string
    add_index :data_sets, :category
  end
end
