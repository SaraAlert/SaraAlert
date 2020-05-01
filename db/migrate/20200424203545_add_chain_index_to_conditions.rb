class AddChainIndexToConditions < ActiveRecord::Migration[6.0]
  def change
    add_index :conditions, [:type, :assessment_id], name: 'conditions_index_chain_1'
  end
end
