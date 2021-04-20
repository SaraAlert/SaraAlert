class AddWasEditedToHistories < ActiveRecord::Migration[6.1]
  def change
    add_column :histories, :was_edited, :boolean, default: false
  end
end
