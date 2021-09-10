class AddAdditionalMonitoreeSnapshotFields < ActiveRecord::Migration[6.1]
  def change
    remove_column :monitoree_snapshots, :isolation_to_exposure, :integer
    remove_column :monitoree_snapshots, :exposure_to_isolation, :integer
    add_column :monitoree_snapshots, :isolation_to_exposure_total, :integer
    add_column :monitoree_snapshots, :exposure_to_isolation_total, :integer
    add_column :monitoree_snapshots, :exposure_to_isolation_active, :integer
    add_column :monitoree_snapshots, :exposure_to_isolation_not_active, :integer
    add_column :monitoree_snapshots, :exposure_to_isolation_closed_in_exposure, :integer
  end
end
