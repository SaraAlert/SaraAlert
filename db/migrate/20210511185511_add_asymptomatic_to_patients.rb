class AddAsymptomaticToPatients < ActiveRecord::Migration[6.1]
  def up
    ActiveRecord::Base.record_timestamps = false

    add_column :patients, :asymptomatic, :boolean, default: false

    ActiveRecord::Base.record_timestamps = true
  end

  def down
    ActiveRecord::Base.record_timestamps = false

    remove_column :patients, :asymptomatic, :boolean, default: false

    ActiveRecord::Base.record_timestamps = true
  end
end
