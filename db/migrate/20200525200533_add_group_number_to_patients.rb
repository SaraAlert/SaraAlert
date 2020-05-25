class AddGroupNumberToPatients < ActiveRecord::Migration[6.0]
  def change
    add_column :patients, :group_number, :integer
    add_index :patients, :group_number
  end
end
