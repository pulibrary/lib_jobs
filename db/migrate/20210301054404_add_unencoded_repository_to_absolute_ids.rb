class AddUnencodedRepositoryToAbsoluteIds < ActiveRecord::Migration[5.2]
  def change
    add_column :absolute_ids, :unencoded_repository, :string
  end
end
