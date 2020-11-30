class AddTimeZoneOffsetToPatients < ActiveRecord::Migration[6.0]
  def up
    add_column :patients, :time_zone_offset, :string
    # Save each non-purged Patient in batches to trigger the
    # before_save callback to set the proper time zone offset.
    Patient.where(purged: false).find_in_batches(batch_size: 1000).with_index do |patients_group, batch|
        puts "  Processing time_zone_offset update batch #{batch + 1}"
        patients_group.each(&:save)
    end
  end

  def down
    remove_column :patients, :time_zone_offset
  end
end
