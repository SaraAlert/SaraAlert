class AddEditedAndDeletedToHistories < ActiveRecord::Migration[6.1]
  def up
    add_column :histories, :deleted_by, :string
    add_column :histories, :delete_reason, :string
    add_column :histories, :original_comment_id, :bigint

    execute <<-SQL.squish
      UPDATE histories
      SET histories.original_comment_id = histories.id
      WHERE history_type = 'Comment'
    SQL
  end

  def down
    remove_column :histories, :deleted_by, :string
    remove_column :histories, :delete_reason, :string
    remove_column :histories, :original_comment_id, :bigint
  end
end
