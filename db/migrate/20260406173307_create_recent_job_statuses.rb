class CreateRecentJobStatuses < ActiveRecord::Migration[8.1]
  def change
    create_table :recent_job_statuses do |t|
      create_enum :status_types, %w[success failure]
      t.string :job, null: false
      t.enum :status, enum_type: :status_types, null: false

      t.timestamps

      t.index :job, unique: true
    end
  end
end
