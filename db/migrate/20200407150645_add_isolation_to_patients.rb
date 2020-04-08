class AddIsolationToPatients < ActiveRecord::Migration[6.0]
  def change
    add_column :patients, :isolation, :boolean, default: false
  end
end
