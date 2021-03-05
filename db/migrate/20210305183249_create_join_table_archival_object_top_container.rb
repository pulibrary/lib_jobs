class CreateJoinTableArchivalObjectTopContainer < ActiveRecord::Migration[5.2]
  def change
    create_join_table :archival_objects, :top_containers do |t|
      t.index :archival_object_id, name: 'archival_object_id'
      t.index :top_container_id, name: 'top_container_id'
    end
  end
end
