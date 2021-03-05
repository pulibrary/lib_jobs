class CreateJoinTableResourceTopContainer < ActiveRecord::Migration[5.2]
  def change
    create_join_table :resources, :top_containers do |t|
      t.index :resource_id, name: 'resource_id'
      t.index :top_container_id, name: 'container_id'
    end
  end
end
