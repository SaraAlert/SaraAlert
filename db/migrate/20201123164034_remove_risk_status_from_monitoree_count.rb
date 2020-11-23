class RemoveRiskStatusFromMonitoreeCount < ActiveRecord::Migration[6.0]
  def change
    remove_column :monitoree_counts, :risk_level
  end
end
