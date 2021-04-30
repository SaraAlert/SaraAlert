class AddEditedAndDeletedToHistories < ActiveRecord::Migration[6.1]
  def change
    add_column :histories, :deleted_by, :string
    add_column :histories, :delete_reason, :string
    add_column :histories, :original_comment_id, :bigint
  end
end
