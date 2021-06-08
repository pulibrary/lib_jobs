# frozen_string_literal: true

class RemoveAbsoluteIDs < ActiveRecord::Migration[5.2]
  def change
    drop_table :absolute_ids
    drop_table :absolute_id_archival_objects
    drop_table :absolute_id_batches
    drop_table :absolute_id_container_profiles
    drop_table :absolute_id_locations
    drop_table :absolute_id_repositories
    drop_table :absolute_id_resources
    drop_table :absolute_id_sessions
    drop_table :absolute_id_top_containers
    drop_table :archival_objects_top_containers
    drop_table :resources_top_containers
  end
end
