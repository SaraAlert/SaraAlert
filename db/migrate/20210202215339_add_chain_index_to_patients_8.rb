class AddChainIndexToPatients8 < ActiveRecord::Migration[6.0]
  def change
    add_index :patients, [:jurisdiction_id, :assigned_user], name: 'patients_index_chain_8'
  end
end
