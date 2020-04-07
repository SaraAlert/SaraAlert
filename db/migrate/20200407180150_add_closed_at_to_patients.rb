class AddClosedAtToPatients < ActiveRecord::Migration[6.0]
  def change
    add_column :patients, :closed_at, :datetime
  end
end
