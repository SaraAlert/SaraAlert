class AddIndexToUserDefinedIdCdc < ActiveRecord::Migration[6.0]
  def change
    add_index :patients, :user_defined_id_cdc
  end
end
