class AddStatusToMonitoreeSnapshot < ActiveRecord::Migration[6.0]
  def up
    add_column :monitoree_snapshots, :status, :string, default: 'Missing'
  end

  def down
    remove_column :monitoree_snapshots, :status, :string
  end
end
