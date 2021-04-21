class AddExposureToIsolationToMonitoreeSnapshot < ActiveRecord::Migration[6.1]
  def change
    add_column :monitoree_snapshots, :exposure_to_isolation, :integer
    add_column :monitoree_snapshots, :isolation_to_exposure, :integer
  end
end
