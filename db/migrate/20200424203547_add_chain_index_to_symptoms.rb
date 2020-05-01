class AddChainIndexToSymptoms < ActiveRecord::Migration[6.0]
  def change
    add_index :symptoms, [:name, :bool_value, :condition_id], name: 'symptoms_index_chain_1'
  end
end
