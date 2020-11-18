class AddChainIndexesToPatients < ActiveRecord::Migration[6.0]
  def change
    add_index :patients, [:purged, :isolation, :last_name, :first_name, :jurisdiction_id], name: 'patients_index_chain_five_1'
    add_index :patients, [:purged, :isolation, :jurisdiction_id], name: 'patients_index_chain_three_2'
  end
end
