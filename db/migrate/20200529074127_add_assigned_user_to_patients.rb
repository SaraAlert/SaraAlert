class AddAssignedUserToPatients < ActiveRecord::Migration[6.0]
  def change
    add_column :patients, :assigned_user, :integer
    add_index :patients, :assigned_user
  end
end
