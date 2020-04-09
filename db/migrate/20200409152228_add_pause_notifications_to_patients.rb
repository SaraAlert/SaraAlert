class AddPauseNotificationsToPatients < ActiveRecord::Migration[6.0]
  def change
    add_column :patients, :pause_notifications, :boolean, default: false
  end
end
