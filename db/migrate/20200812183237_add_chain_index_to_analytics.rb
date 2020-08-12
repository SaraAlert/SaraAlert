class AddChainIndexToAnalytics < ActiveRecord::Migration[6.0]
  def change
    add_index :analytics, [:jurisdiction_id, :created_at, :id], name: 'analytics_index_chain_1'
  end
end
