class AddChainIndexToPatients < ActiveRecord::Migration[6.0]
  def change
    add_index :patients, [:monitoring, :purged, :public_health_action, :isolation, :jurisdiction_id], name: 'patients_index_chain_1'
    add_index :patients, [:monitoring, :purged, :isolation, :jurisdiction_id], name: 'patients_index_chain_2'
    add_index :patients, [:last_name, :first_name], name: 'patients_index_chain_3'
    add_index :patients, [:id, :monitoring, :purged, :isolation, :symptom_onset], name: 'patients_index_chain_4'
    add_index :patients, [:monitoring, :purged, :isolation, :id, :public_health_action], name: 'patients_index_chain_5'
    add_index :patients, [:isolation, :jurisdiction_id], name: 'patients_index_chain_6'
    remove_index :patients, name: 'index_patients_on_last_name'
    remove_index :patients, name: 'index_patients_on_monitoring'
  end
end
