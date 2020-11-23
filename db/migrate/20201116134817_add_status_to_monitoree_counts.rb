class AddStatusToMonitoreeCounts < ActiveRecord::Migration[6.0]
  def up
    add_column :monitoree_counts, :status, :string, default: 'Missing'
  end

  def down
    remove_column :monitoree_counts, :status, :string
  end
end
