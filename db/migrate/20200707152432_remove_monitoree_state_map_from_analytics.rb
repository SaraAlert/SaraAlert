class RemoveMonitoreeStateMapFromAnalytics < ActiveRecord::Migration[6.0]
  def change
    remove_column :analytics, :monitoree_state_map
  end
end
