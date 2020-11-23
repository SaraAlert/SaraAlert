class AddTimeZoneOffsetToPatients < ActiveRecord::Migration[6.0]
  def change
    add_column :patients, :time_zone_offset, :string
  end
end
