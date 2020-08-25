class AddChainIndex3ToConditions < ActiveRecord::Migration[6.0]
  def change
    add_index :conditions, [:type, :jurisdiction_id], name: 'conditions_index_chain_3'
  end
end
