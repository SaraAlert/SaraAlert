class AddArchivedToHistories < ActiveRecord::Migration[6.1]
  def change
    add_column :histories, :archived, :boolean, default: false
    add_column :histories, :archived_by, :string
    add_column :histories, :latest_version, :boolean, default: true
    add_column :histories, :original_comment_id, :bigint
  end
end
