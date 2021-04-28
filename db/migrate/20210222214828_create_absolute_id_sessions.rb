class CreateAbsoluteIdSessions < ActiveRecord::Migration[5.2]
  def change
    create_table :absolute_id_sessions do |t|

      t.timestamps
    end
  end
end
