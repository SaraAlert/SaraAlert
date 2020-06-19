class AddMoreIndexesToPatients < ActiveRecord::Migration[6.0]
  def change
    add_index :patients, [:monitoring, :purged, :isolation], name: 'patients_index_chain_7'
    add_index :patients, [:id], name: 'index_patients_on_id'
  end
end
