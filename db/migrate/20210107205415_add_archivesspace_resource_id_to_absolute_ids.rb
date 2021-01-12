class AddArchivesspaceResourceIdToAbsoluteIds < ActiveRecord::Migration[5.2]
  def change
    change_table :absolute_ids do |t|
      t.string :archivesspace_resource_id
    end
  end
end
