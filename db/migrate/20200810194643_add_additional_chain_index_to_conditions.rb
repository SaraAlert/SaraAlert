class AddAdditionalChainIndexToConditions < ActiveRecord::Migration[6.0]
  def change
    add_index :conditions, [:type, :threshold_condition_hash, :id], name: 'conditions_index_chain_2'
  end
end
