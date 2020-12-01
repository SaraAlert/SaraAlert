class RemoveContentsAndLookupFromDownloads < ActiveRecord::Migration[6.0]
  def change
    remove_column :downloads, :lookup
    remove_column :downloads, :contents
  end
end
