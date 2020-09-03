class AddChainIndexToPatientsThree < ActiveRecord::Migration[6.0]
  def change
    add_index :patients, [:jurisdiction_id, :isolation, :purged, :assigned_user], name: 'patients_index_chain_three_1'
  end
end
