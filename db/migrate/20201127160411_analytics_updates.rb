class AnalyticsUpdates < ActiveRecord::Migration[6.0]
  def up
    remove_column :monitoree_counts, :risk_level
    add_column :monitoree_counts, :status, :string
    add_column :monitoree_snapshots, :status, :string, default: 'Missing'
  end

  def down
    add_column :monitoree_counts, :risk_level
    remove_column :monitoree_counts, :status, :string
    remove_column :monitoree_snapshots, :status, :string
  end

end
