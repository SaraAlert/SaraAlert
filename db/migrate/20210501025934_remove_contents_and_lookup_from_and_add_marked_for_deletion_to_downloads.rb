class RemoveContentsAndLookupFromAndAddMarkedForDeletionToDownloads < ActiveRecord::Migration[6.0]
  def change
    remove_column :downloads, :lookup, :string
    remove_column :downloads, :contents, :binary
    add_column :downloads, :marked_for_deletion, :boolean, default: false
  end
end
