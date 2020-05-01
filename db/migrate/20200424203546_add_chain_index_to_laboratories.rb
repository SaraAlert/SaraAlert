class AddChainIndexToLaboratories < ActiveRecord::Migration[6.0]
  def change
    add_index :laboratories, [:result, :patient_id], name: 'laboratories_index_chain_1'
  end
end
