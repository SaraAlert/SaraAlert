class AddColumnsForCaseDevelopmentAnalytics < ActiveRecord::Migration[6.1]
  def change
    remove_column :monitoree_snapshots, :isolation_to_exposure, :integer
    remove_column :monitoree_snapshots, :exposure_to_isolation, :integer

    add_column :monitoree_snapshots, :exposure_to_isolation_active, :integer
    add_column :monitoree_snapshots, :exposure_to_isolation_not_active, :integer
    add_column :monitoree_snapshots, :cases_closed_in_exposure, :integer
    add_column :monitoree_snapshots, :isolation_to_exposure, :integer

    add_column :patients, :enrolled_workflow, :string
    add_column :patients, :isolation_to_exposure_at, :datetime, precision: 6
    add_column :patients, :exposure_to_isolation_at, :datetime, precision: 6
  end
end
