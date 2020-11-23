class AddTimeZoneOffsetToPatients < ActiveRecord::Migration[6.0]
  def up
    add_column :patients, :time_zone_offset, :string
    # -04:00 was being used before and we expect it to be updated
    # to the proper value the next time each patient is saved.
    Patient.update_all(time_zone_offset: '-04:00')
  end

  def down
    remove_column :patients, :time_zone_offset
  end
end
