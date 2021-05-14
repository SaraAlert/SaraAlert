class AddFollowUpFlagFieldsToPatients < ActiveRecord::Migration[6.1]
  def up
    ActiveRecord::Base.record_timestamps = false

    add_column :patients, :follow_up_reason, :string
    add_column :patients, :follow_up_note, :text

    ActiveRecord::Base.record_timestamps = true
  end

  def down
    ActiveRecord::Base.record_timestamps = false

    remove_column :patients, :follow_up_reason
    remove_column :patients, :follow_up_note

    ActiveRecord::Base.record_timestamps = true
  end
end
