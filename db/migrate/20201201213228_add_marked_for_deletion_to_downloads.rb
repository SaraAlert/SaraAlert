class AddMarkedForDeletionToDownloads < ActiveRecord::Migration[6.0]
  def change
    add_column :downloads, :marked_for_deletion, :boolean, default: false
  end
end
