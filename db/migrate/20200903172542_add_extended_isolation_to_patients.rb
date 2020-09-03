class AddExtendedIsolationToPatients < ActiveRecord::Migration[6.0]
  def change
    add_column :patients, :extended_isolation, :date
  end
end
